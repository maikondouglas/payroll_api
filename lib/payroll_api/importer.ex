defmodule PayrollApi.Payroll.Importer do
  @moduledoc """
  Importa folha de pagamento via CSV no modelo enterprise.

  Fluxo da importação:
  1. Carrega rubricas uma única vez para cache em memória (code -> id)
  2. Lê e valida o CSV
  3. Para cada linha, busca o funcionário por matrícula ou CPF
  4. Cria o payslip
  5. Insere os payslip_items em lote com insert_all

  Todo o arquivo roda em uma única transação com Ecto.Multi. Se qualquer
  linha falhar, nada é persistido.
  """

  import Ecto.Query, warn: false

  alias NimbleCSV.RFC4180, as: CSV
  alias Ecto.Multi
  alias PayrollApi.HR.Employee
  alias PayrollApi.Payroll.{Payslip, PayslipItem, Rubric}
  alias PayrollApi.Repo

  require Logger

  @doc """
  Importa um arquivo CSV de folha de pagamento.

  ## Parâmetros
    * `file_path` - Caminho do arquivo CSV
    * `competence_date` - Data de competência (mês/ano) no formato ~D[2024-01-01]

  ## Retorno
    * `{:ok, %{success: integer, errors: integer, details: list}}`
    * `{:error, reason}`
  """
  def import_csv(file_path, competence_date) do
    try do
      Multi.new()
      |> Multi.run(:rubric_cache, fn repo, _changes -> {:ok, load_rubric_cache(repo)} end)
      |> Multi.run(:csv_data, fn _repo, _changes -> read_csv(file_path) end)
      |> Multi.run(:import, fn repo, %{rubric_cache: rubric_cache, csv_data: {headers, rows}} ->
        with {:ok, rubric_columns} <- build_rubric_column_map(headers, rubric_cache),
             {:ok, result} <- import_rows(repo, rows, competence_date, rubric_columns) do
          {:ok, result}
        end
      end)
      |> Repo.transaction()
      |> case do
        {:ok, %{import: result}} ->
          Logger.info("Importação concluída com sucesso: #{result.success} linhas processadas")
          {:ok, result}

        {:error, _step, reason, _changes_so_far} ->
          Logger.error("Importação cancelada. Nenhuma linha foi persistida: #{inspect(reason)}")
          {:error, reason}
      end
    rescue
      e in File.Error ->
        Logger.error("Erro ao ler arquivo: #{inspect(e)}")
        {:error, "Arquivo não encontrado ou inacessível"}

      e ->
        Logger.error("Erro inesperado na importação: #{inspect(e)}")
        {:error, "Erro ao processar arquivo CSV"}
    end
  end

  defp read_csv(file_path) do
    rows =
      file_path
      |> File.stream!()
      |> CSV.parse_stream()
      |> Enum.to_list()

    case rows do
      [] ->
        {:error, "Arquivo CSV vazio"}

      _ ->
        case find_header_row(rows) do
          {:ok, header_index, headers} ->
            data_rows = Enum.drop(rows, header_index + 1)
            {:ok, {headers, data_rows}}

          :error ->
            case rows do
              [first_row | _rest] when is_list(first_row) and length(first_row) >= 19 ->
                # Fallback para arquivos que chegam sem cabeçalho parseável.
                {:ok, {default_headers(), rows}}

              _ ->
                {:error,
                 "Cabeçalho CSV inválido. A primeira linha deve conter: Matrícula, CPF, Nome, Salário Líquido e Salário Base."}
            end
        end
    end
  end

  defp find_header_row(rows) do
    rows
    |> Enum.with_index()
    |> Enum.find_value(:error, fn {row, index} ->
      if valid_csv_header?(row), do: {:ok, index, row}, else: false
    end)
  end

  defp valid_csv_header?(headers) when is_list(headers) do
    normalized = Enum.map(headers, &normalize_header/1)

    col0 = Enum.at(normalized, 0, "")
    col1 = Enum.at(normalized, 1, "")
    col2 = Enum.at(normalized, 2, "")

    has_required_columns? =
      String.starts_with?(col0, "matricula") and
        String.starts_with?(col1, "cpf") and
        String.starts_with?(col2, "nome") and
        Enum.any?(normalized, &String.contains?(&1, "salario liquido")) and
        Enum.any?(normalized, &String.contains?(&1, "salario base"))

    has_required_columns? and length(headers) >= 8
  end

  defp valid_csv_header?(_), do: false

  # Cache em memória para evitar N+1 de rubricas durante o processamento das linhas.
  defp load_rubric_cache(repo) do
    rubrics = repo.all(from r in Rubric, select: {r.code, r.description, r.id})

    by_code = Map.new(rubrics, fn {code, _description, id} -> {normalize_code(code), id} end)

    by_description =
      Map.new(rubrics, fn {code, description, id} ->
        {normalize_header(description), %{id: id, code: normalize_code(code)}}
      end)

    %{by_code: by_code, by_description: by_description}
  end

  defp build_rubric_column_map(headers, rubric_cache) do
    headers
    |> Enum.with_index()
    |> Enum.drop(7)
    |> Enum.reduce_while({:ok, %{}}, fn {header, index}, {:ok, acc} ->
      case resolve_rubric_mapping(header, rubric_cache) do
        {:ok, nil} ->
          {:cont, {:ok, acc}}

        {:ok, rubric_data} ->
          {:cont, {:ok, Map.put(acc, index, rubric_data)}}

        {:error, reason} ->
          {:halt, {:error, reason}}
      end
    end)
  end

  # Aceita cabeçalho em formato de código (ex: 001, 805, 001 - INSS)
  # e também fallback por descrição para suportar arquivos legados.
  defp resolve_rubric_mapping(header, %{by_code: by_code, by_description: by_description}) do
    normalized_header = normalize_header(header)

    case extract_rubric_code(header) do
      nil ->
        case Map.get(by_description, normalized_header) do
          nil -> {:ok, nil}
          rubric -> {:ok, rubric}
        end

      code ->
        normalized_code = normalize_code(code)

        case Map.get(by_code, normalized_code) do
          nil -> {:error, "Rubrica com código #{normalized_code} não cadastrada"}
          rubric_id -> {:ok, %{id: rubric_id, code: normalized_code}}
        end
    end
  end

  defp import_rows(repo, rows, competence_date, rubric_columns) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    rows
    |> Enum.with_index(2)
    |> Enum.reduce_while({:ok, %{success: 0, errors: 0, details: []}}, fn {row, line_number},
                                                                           {:ok, acc} ->
      case import_row(repo, row, line_number, competence_date, rubric_columns, now) do
        {:ok, row_result} ->
          updated = %{acc | success: acc.success + 1, details: [{:ok, row_result} | acc.details]}
          {:cont, {:ok, updated}}

        {:error, reason} ->
          {:halt, {:error, %{line: line_number, reason: reason}}}
      end
    end)
    |> case do
      {:ok, result} -> {:ok, %{result | details: Enum.reverse(result.details)}}
      error -> error
    end
  end

  defp import_row(repo, row, line_number, competence_date, rubric_columns, now) do
    with {:ok, registration} <- extract_field(row, 0, "Matrícula"),
         {:ok, cpf} <- extract_cpf(row, 1),
         {:ok, name} <- extract_field(row, 2, "Nome"),
         {:ok, net_salary} <- parse_decimal(Enum.at(row, 5)),
         {:ok, base_salary} <- parse_decimal(Enum.at(row, 6)),
         {:ok, employee_id} <- find_employee_id(repo, registration, cpf),
         {:ok, payslip} <-
           create_payslip(repo, employee_id, competence_date, base_salary, net_salary, %{}),
         {:ok, item_entries, details_map} <-
           build_payslip_item_entries(row, rubric_columns, payslip.id, now),
         :ok <- insert_payslip_items(repo, item_entries) do
      # Mantém informações úteis por linha para resposta da API.
      {:ok,
       %{
         line: line_number,
         registration: registration,
         cpf: cpf,
         name: name,
         payslip_id: payslip.id,
         items_count: length(item_entries),
         details: details_map
       }}
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        {:error, %{message: "Falha ao salvar dados", details: format_changeset_errors(changeset)}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp extract_field(row, index, field_name) do
    case Enum.at(row, index) do
      nil -> {:error, "#{field_name} vazio"}
      "" -> {:error, "#{field_name} vazio"}
      value -> {:ok, String.trim(value)}
    end
  end

  defp extract_cpf(row, index) do
    case Enum.at(row, index) do
      nil ->
        {:error, "CPF vazio"}

      "" ->
        {:error, "CPF vazio"}

      cpf ->
        cleaned_cpf =
          cpf
          |> String.trim()
          |> String.replace(~r/[.\-\s]/, "")

        if String.length(cleaned_cpf) == 11 do
          {:ok, cleaned_cpf}
        else
          {:error, "CPF inválido: #{cpf}"}
        end
    end
  end

  defp find_employee_id(repo, registration, cpf) do
    query =
      from e in Employee,
        join: u in assoc(e, :user),
        where: e.registration == ^registration or u.cpf == ^cpf,
        select: e.id,
        limit: 1

    case repo.one(query) do
      nil -> {:error, "Funcionário não encontrado para matrícula #{registration} / CPF #{cpf}"}
      employee_id -> {:ok, employee_id}
    end
  end

  defp create_payslip(repo, employee_id, competence_date, base_salary, net_salary, details) do
    attrs = %{
      employee_id: employee_id,
      competence: competence_date,
      base_salary: base_salary,
      net_salary: net_salary,
      details: details
    }

    case Payslip.changeset(%Payslip{}, attrs) |> repo.insert() do
      {:ok, payslip} -> {:ok, payslip}
      {:error, changeset} -> {:error, changeset}
    end
  end

  defp build_payslip_item_entries(row, rubric_columns, payslip_id, now) do
    rubric_columns
    |> Enum.reduce_while({:ok, [], %{}}, fn {index, %{id: rubric_id, code: code}},
                                            {:ok, entries, details_acc} ->
      raw_value = Enum.at(row, index, "")

      case parse_item_value(raw_value) do
        {:ok, nil} ->
          {:cont, {:ok, entries, details_acc}}

        {:ok, %{reference: reference, amount: amount}} ->
          entry = %{
            payslip_id: payslip_id,
            rubric_id: rubric_id,
            reference: reference,
            amount: amount,
            inserted_at: now,
            updated_at: now
          }

          # Mantém campo legado `details` preenchido para compatibilidade temporária.
          details_value = if reference, do: reference, else: Decimal.to_string(amount)

          {:cont, {:ok, [entry | entries], Map.put(details_acc, code, details_value)}}

        {:error, reason} ->
          {:halt, {:error, reason}}
      end
    end)
    |> case do
      {:ok, entries, details_map} -> {:ok, Enum.reverse(entries), details_map}
      error -> error
    end
  end

  defp insert_payslip_items(_repo, []), do: :ok

  defp insert_payslip_items(repo, entries) do
    case repo.insert_all(PayslipItem, entries) do
      {count, _} when count == length(entries) -> :ok
      {count, _} -> {:error, "Nem todos os payslip_items foram inseridos (#{count}/#{length(entries)})"}
    end
  end

  # Converte string para Decimal, tratando valores BR e EN.
  defp parse_decimal(nil), do: {:ok, Decimal.new("0")}
  defp parse_decimal(""), do: {:ok, Decimal.new("0")}

  defp parse_decimal(value) when is_binary(value) do
    cleaned_value =
      value
      |> String.replace("R$", "")
      |> String.trim()

    final_value =
      if String.contains?(cleaned_value, ",") do
        cleaned_value
        |> String.replace(".", "")
        |> String.replace(",", ".")
      else
        cleaned_value
      end

    case Decimal.parse(final_value) do
      {decimal, _} -> {:ok, decimal}
      :error -> {:error, "Valor decimal inválido: #{value}"}
    end
  end

  # Se não houver valor, ignora a rubrica na linha.
  # Se for um valor monetário, salva em `amount`.
  # Se for uma referência como "220:00" ou "11%", salva em `reference`
  # e usa amount 0 para manter consistência do schema.
  defp parse_item_value(raw_value) when is_binary(raw_value) do
    value = String.trim(raw_value)

    cond do
      value == "" ->
        {:ok, nil}

      true ->
        case parse_decimal(value) do
          {:ok, amount} ->
            {:ok, %{reference: nil, amount: amount}}

          {:error, _} ->
            if reference_format?(value) do
              {:ok, %{reference: value, amount: Decimal.new("0")}}
            else
              {:error, "Valor de rubrica inválido: #{value}"}
            end
        end
    end
  end

  defp parse_item_value(_), do: {:error, "Valor de rubrica inválido"}

  defp reference_format?(value) do
    String.contains?(value, ":") or String.ends_with?(value, "%")
  end

  defp extract_rubric_code(header) do
    # Código de rubrica só é aceito quando aparece no início do cabeçalho,
    # como "001 - Salário Base".
    case Regex.run(~r/^\s*(\d{3})(?:\b|\s*[-–:])/u, header || "") do
      [_, code] -> code
      _ -> nil
    end
  end

  defp normalize_header(value) do
    value
    |> to_string()
    |> String.replace_prefix("\uFEFF", "")
    |> String.downcase()
    |> String.normalize(:nfd)
    |> String.replace(~r/[\p{Mn}]/u, "")
    |> String.replace(~r/[^\p{L}\p{N}]+/u, " ")
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
  end

  defp default_headers do
    [
      "Matrícula",
      "CPF",
      "Nome",
      "Salário Contratual",
      "Função",
      "Salário Líquido",
      "Salário Base",
      "001 - Salário Base",
      "Adicional Noturno",
      "901 - Desconto INSS",
      "Complemento Salarial",
      "Complemento do Piso da Enfermagem",
      "Desconto em Horas",
      "IRRF Folha",
      "Desconto em Horas 16h",
      "Complemento Salarial (12H)",
      "Faltas em Dias",
      "Desconto de DSR Sobre Faltas",
      "RT - 50% (GRATIFICACAO)"
    ]
  end

  defp normalize_code(value) do
    value
    |> to_string()
    |> String.trim()
  end

  defp format_changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
end
