defmodule PayrollApi.Payroll.Importer do
  @moduledoc """
  Módulo para importação de dados de folha de pagamento via CSV.
  """

  alias NimbleCSV.RFC4180, as: CSV
  alias PayrollApi.{HR, Payroll}

  require Logger

  @doc """
  Importa um arquivo CSV de folha de pagamento criando registros de Payslip.

  ## Parâmetros
    * `file_path` - Caminho do arquivo CSV
    * `competence_date` - Data de competência (mês/ano) no formato ~D[2024-01-01]

  ## Estrutura do CSV
  Matrícula,Nome,Salário Contratual,Função,Salário Líquido,Salário Base,GRATIFICAÇÃO COMPLEMENTAR,...

  ## Retorno
    * `{:ok, results}` - Lista com resultados da importação
    * `{:error, reason}` - Em caso de erro na leitura do arquivo

  ## Exemplo
      iex> PayrollApi.Payroll.Importer.import_csv("/path/to/file.csv", ~D[2024-01-01])
      {:ok, %{success: 10, errors: 0, details: [...]}}
  """
  def import_csv(file_path, competence_date) do
    # Headers do CSV para identificar as colunas de rubricas
    headers = [
      "Matrícula",
      "Nome",
      "Salário Contratual",
      "Função",
      "Salário Líquido",
      "Salário Base",
      "GRATIFICAÇÃO COMPLEMENTAR",
      "Adicional Noturno",
      "INSS Folha",
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

    try do
      results =
        file_path
        |> File.stream!()
        |> CSV.parse_stream(skip_headers: true)
        |> Enum.map(&process_row(&1, headers, competence_date))

      success_count = Enum.count(results, fn {status, _} -> status == :ok end)
      error_count = Enum.count(results, fn {status, _} -> status == :error end)

      Logger.info("Importação concluída: #{success_count} sucessos, #{error_count} erros")

      {:ok,
       %{
         success: success_count,
         errors: error_count,
         details: results
       }}
    rescue
      e in File.Error ->
        Logger.error("Erro ao ler arquivo: #{inspect(e)}")
        {:error, "Arquivo não encontrado ou inacessível"}

      e ->
        Logger.error("Erro inesperado na importação: #{inspect(e)}")
        {:error, "Erro ao processar arquivo CSV"}
    end
  end

  # Processa uma linha individual do CSV
  defp process_row(row, headers, competence_date) do
    with {:ok, registration} <- extract_registration(row),
         {:ok, base_salary} <- parse_decimal(Enum.at(row, 5)),
         {:ok, net_salary} <- parse_decimal(Enum.at(row, 4)),
         {:ok, details} <- build_details_map(row, headers),
         {:ok, employee} <- find_employee(registration),
         {:ok, payslip} <- create_payslip(employee, competence_date, base_salary, net_salary, details) do
      Logger.debug("Payslip criado para matrícula #{registration}")
      {:ok, %{registration: registration, payslip_id: payslip.id}}
    else
      {:error, :employee_not_found, registration} ->
        Logger.warning("Funcionário não encontrado: #{registration}")
        {:error, %{registration: registration, reason: "Funcionário não encontrado"}}

      {:error, :invalid_decimal, field} ->
        Logger.warning("Valor decimal inválido no campo: #{field}")
        {:error, %{registration: Enum.at(row, 0), reason: "Valor decimal inválido em #{field}"}}

      {:error, :empty_registration} ->
        Logger.warning("Matrícula vazia na linha")
        {:error, %{registration: nil, reason: "Matrícula vazia"}}

      {:error, %Ecto.Changeset{} = changeset} ->
        errors = format_changeset_errors(changeset)
        Logger.warning("Erro de validação: #{inspect(errors)}")
        {:error, %{registration: Enum.at(row, 0), reason: "Erro de validação", details: errors}}

      {:error, reason} ->
        Logger.error("Erro desconhecido: #{inspect(reason)}")
        {:error, %{registration: Enum.at(row, 0), reason: inspect(reason)}}
    end
  end

  # Extrai e valida a matrícula
  defp extract_registration(row) do
    case Enum.at(row, 0) do
      nil -> {:error, :empty_registration}
      "" -> {:error, :empty_registration}
      registration -> {:ok, String.trim(registration)}
    end
  end

  # Converte string para Decimal, tratando vírgulas e pontos
  defp parse_decimal(nil), do: {:ok, Decimal.new("0")}
  defp parse_decimal(""), do: {:ok, Decimal.new("0")}

  defp parse_decimal(value) when is_binary(value) do
    # 1. Remove o "R$" e espaços em branco
    cleaned_value =
      value
      |> String.replace("R$", "")
      |> String.trim()

    # 2. Se tiver vírgula, é formato BR. Removemos o ponto de milhar e trocamos vírgula por ponto.
    final_value =
      if String.contains?(cleaned_value, ",") do
        cleaned_value
        |> String.replace(".", "")   # Ex: 1.621,00 vira 1621,00
        |> String.replace(",", ".")  # Ex: 1621,00 vira 1621.00
      else
        cleaned_value # Se já for "1621" ou "1621.00", mantém intacto
      end

    case Decimal.parse(final_value) do
      {decimal, _} -> {:ok, decimal}
      :error -> {:error, :invalid_decimal, value}
    end
  end

  # Constrói o mapa de detalhes com todas as rubricas
  defp build_details_map(row, headers) do
    # Índices das rubricas extras (a partir da coluna 6)
    details =
      headers
      |> Enum.drop(6)
      |> Enum.with_index(6)
      |> Enum.reduce(%{}, fn {header, index}, acc ->
        value = Enum.at(row, index, "")

        # Só adiciona ao map se o valor não estiver vazio
        case String.trim(value) do
          "" ->
            acc

          trimmed_value ->
            # Tenta converter para decimal se possível, senão mantém como string
            case parse_decimal(trimmed_value) do
              {:ok, decimal} ->
                Map.put(acc, header, Decimal.to_string(decimal))

              _ ->
                Map.put(acc, header, trimmed_value)
            end
        end
      end)

    {:ok, details}
  end

  # Busca o funcionário pela matrícula
  defp find_employee(registration) do
    case HR.get_employee_by_registration(registration) do
      nil -> {:error, :employee_not_found, registration}
      employee -> {:ok, employee}
    end
  end

  # Cria o payslip no banco de dados
  defp create_payslip(employee, competence_date, base_salary, net_salary, details) do
    attrs = %{
      employee_id: employee.id,
      competence: competence_date,
      base_salary: base_salary,
      net_salary: net_salary,
      details: details
    }

    case Payroll.create_payslip(attrs) do
      {:ok, payslip} -> {:ok, payslip}
      {:error, changeset} -> {:error, changeset}
    end
  end

  # Formata erros do changeset para log
  defp format_changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
end
