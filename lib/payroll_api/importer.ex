NimbleCSV.define(PayrollApi.Payroll.CSVSemicolon, separator: ";", escape: "\"")

defmodule PayrollApi.Payroll.Importer do
  @moduledoc """
  Importador transacional de folha de pagamento (dados financeiros).

  Regras:
  - Nao cria usuario/funcionario.
  - Espera matricula na primeira coluna e rubricas (codigos) nas demais.
  - Usa cache em memoria para Employees e Rubrics.
  """

  import Ecto.Query, warn: false

  alias Ecto.Multi
  alias NimbleCSV.RFC4180
  alias PayrollApi.HR.Employee
  alias PayrollApi.Payroll.{Payslip, PayslipItem, Rubric}
  alias PayrollApi.Repo

  require Logger

  @base_salary_code "001"

  def import_csv(file_path, competence_date) do
    Multi.new()
    |> Multi.run(:employee_cache, fn repo, _ -> {:ok, load_employee_cache(repo)} end)
    |> Multi.run(:rubric_cache, fn repo, _ -> {:ok, load_rubric_cache(repo)} end)
    |> Multi.run(:csv_data, fn _repo, _ -> read_csv(file_path) end)
    |> Multi.run(:import, fn repo, %{employee_cache: employee_cache, rubric_cache: rubric_cache, csv_data: csv_data} ->
      do_import(repo, csv_data, employee_cache, rubric_cache, competence_date)
    end)
    |> Repo.transaction(timeout: :infinity, pool_timeout: 60_000)
    |> case do
      {:ok, %{import: result}} -> {:ok, result}
      {:error, _step, reason, _changes} -> {:error, reason}
    end
  rescue
    e in File.Error ->
      Logger.error("Erro ao ler arquivo CSV: #{inspect(e)}")
      {:error, "Arquivo CSV nao encontrado ou inacessivel"}

    e in DBConnection.ConnectionError ->
      {:error, %{message: "Falha de conexao com banco durante importacao", type: "ConnectionError", exception: Exception.message(e)}}

    e ->
      Logger.error("Erro inesperado no importador financeiro: #{inspect(e)}")
      {:error, %{message: "Erro inesperado ao processar arquivo CSV", type: e.__struct__ |> Module.split() |> List.last(), exception: Exception.message(e)}}
  end

  defp do_import(repo, {headers, rows}, employee_cache, rubric_cache, competence_date) do
    with {:ok, rubric_columns} <- build_rubric_columns(headers, rubric_cache),
         {:ok, result} <- import_rows(repo, rows, competence_date, employee_cache, rubric_columns) do
      {:ok, result}
    end
  end

  defp read_csv(file_path) do
    parser = detect_parser(file_path)

    rows =
      file_path
      |> File.stream!()
      |> parser.parse_stream(skip_headers: false)
      |> Enum.to_list()

    case rows do
      [] -> {:error, "Arquivo CSV vazio"}
      [headers | data_rows] -> {:ok, {headers, data_rows}}
    end
  end

  defp detect_parser(file_path) do
    first_line = file_path |> File.stream!() |> Enum.take(1) |> List.first("")

    if count_occurrences(first_line, ";") > count_occurrences(first_line, ",") do
      PayrollApi.Payroll.CSVSemicolon
    else
      RFC4180
    end
  end

  defp count_occurrences(text, token) do
    text
    |> String.split(token)
    |> length()
    |> Kernel.-(1)
    |> max(0)
  end

  defp load_employee_cache(repo) do
    repo.all(from e in Employee, select: {e.registration, e.id})
    |> Map.new(fn {registration, id} -> {String.trim(to_string(registration)), id} end)
  end

  defp load_rubric_cache(repo) do
    repo.all(from r in Rubric, select: {r.code, r.id})
    |> Map.new(fn {code, id} -> {normalize_code(code), id} end)
  end

  defp build_rubric_columns(headers, rubric_cache) do
    headers
    |> Enum.with_index()
    |> Enum.reduce_while({:ok, []}, fn {header, index}, {:ok, acc} ->
      if index == 0 do
        {:cont, {:ok, acc}}
      else
        case extract_rubric_code(header) do
          nil ->
            {:halt, {:error, "Cabecalho de rubrica invalido na coluna #{index + 1}: #{header}"}}

          code ->
            case Map.get(rubric_cache, code) do
              nil -> {:halt, {:error, "Rubrica com codigo #{code} nao cadastrada"}}
              rubric_id -> {:cont, {:ok, [%{index: index, code: code, rubric_id: rubric_id} | acc]}}
            end
        end
      end
    end)
    |> case do
      {:ok, columns} -> {:ok, Enum.reverse(columns)}
      error -> error
    end
  end

  defp import_rows(repo, rows, competence_date, employee_cache, rubric_columns) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    rows
    |> Enum.with_index(2)
    |> Enum.reduce_while({:ok, %{success: 0, errors: 0, details: []}}, fn {row, line_number}, {:ok, acc} ->
      if blank_row?(row) do
        {:cont, {:ok, acc}}
      else
        case import_row(repo, row, line_number, competence_date, employee_cache, rubric_columns, now) do
          {:ok, row_result} ->
            next = %{acc | success: acc.success + 1, details: [{:ok, row_result} | acc.details]}
            {:cont, {:ok, next}}

          {:error, reason} ->
            {:halt, {:error, %{line: line_number, reason: reason}}}
        end
      end
    end)
    |> case do
      {:ok, result} -> {:ok, %{result | details: Enum.reverse(result.details)}}
      error -> error
    end
  end

  defp import_row(repo, row, line_number, competence_date, employee_cache, rubric_columns, now) do
    with {:ok, registration} <- extract_registration(row),
         {:ok, employee_id} <- find_employee_id(employee_cache, registration),
         {:ok, base_salary, entries, details_map} <- build_financial_payload(row, rubric_columns),
         {:ok, payslip} <- create_payslip(repo, employee_id, competence_date, base_salary),
         :ok <- insert_items(repo, payslip.id, entries, now) do
      {:ok,
       %{
         line: line_number,
         registration: registration,
         payslip_id: payslip.id,
         items_count: length(entries),
         details: details_map
       }}
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        {:error, %{message: "Falha ao salvar dados na linha #{line_number}", details: format_changeset_errors(changeset)}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp extract_registration(row) do
    case row |> Enum.at(0) |> to_string() |> String.trim() do
      "" -> {:error, "Matricula vazia"}
      registration -> {:ok, registration}
    end
  end

  defp find_employee_id(employee_cache, registration) do
    case Map.get(employee_cache, registration) do
      nil -> {:error, "Matricula #{registration} nao encontrada. Cadastre o funcionario primeiro."}
      employee_id -> {:ok, employee_id}
    end
  end

  defp build_financial_payload(row, rubric_columns) do
    rubric_columns
    |> Enum.reduce_while({:ok, Decimal.new("0"), [], %{}}, fn %{index: index, code: code, rubric_id: rubric_id}, {:ok, base_salary, entries, details} ->
      raw_value = Enum.at(row, index, "")

      case parse_decimal(raw_value) do
        {:ok, amount} ->
          next_details = Map.put(details, code, Decimal.to_string(amount))

          cond do
            code == @base_salary_code ->
              {:cont, {:ok, amount, entries, next_details}}

            Decimal.compare(amount, Decimal.new("0")) == :gt ->
              entry = %{rubric_id: rubric_id, amount: amount, reference: nil}
              {:cont, {:ok, base_salary, [entry | entries], next_details}}

            true ->
              {:cont, {:ok, base_salary, entries, next_details}}
          end

        {:error, reason} ->
          {:halt, {:error, reason}}
      end
    end)
    |> case do
      {:ok, base_salary, entries, details} ->
        effective_base =
          if Decimal.compare(base_salary, Decimal.new("0")) == :gt do
            base_salary
          else
            Decimal.new("0.01")
          end

        {:ok, effective_base, Enum.reverse(entries), details}

      error ->
        error
    end
  end

  defp create_payslip(repo, employee_id, competence_date, base_salary) do
    attrs = %{
      employee_id: employee_id,
      competence: competence_date,
      base_salary: base_salary,
      net_salary: base_salary,
      details: %{}
    }

    repo.insert(Payslip.changeset(%Payslip{}, attrs))
  end

  defp insert_items(_repo, _payslip_id, [], _now), do: :ok

  defp insert_items(repo, payslip_id, entries, now) do
    prepared =
      Enum.map(entries, fn entry ->
        %{
          payslip_id: payslip_id,
          rubric_id: entry.rubric_id,
          amount: entry.amount,
          reference: entry.reference,
          inserted_at: now,
          updated_at: now
        }
      end)

    case repo.insert_all(PayslipItem, prepared) do
      {count, _} when count == length(prepared) -> :ok
      {count, _} -> {:error, "Falha ao inserir itens de rubrica (#{count}/#{length(prepared)})"}
    end
  end

  defp parse_decimal(nil), do: {:ok, Decimal.new("0")}

  defp parse_decimal(value) when is_binary(value) do
    normalized =
      value
      |> String.replace(~r/[[:space:]]/u, "")
      |> String.replace("R$", "")
      |> String.trim()
      |> normalize_decimal_string()

    case Decimal.parse(normalized) do
      {decimal, _} -> {:ok, decimal}
      :error -> {:error, "Valor decimal invalido: #{value}"}
    end
  end

  defp parse_decimal(value), do: value |> to_string() |> parse_decimal()

  defp normalize_decimal_string(value) do
    has_dot = String.contains?(value, ".")
    has_comma = String.contains?(value, ",")

    cond do
      value == "" -> "0"
      has_dot and has_comma -> value |> String.replace(".", "") |> String.replace(",", ".")
      has_comma -> String.replace(value, ",", ".")
      true -> value
    end
  end

  defp extract_rubric_code(header) do
    header
    |> to_string()
    |> String.trim()
    |> case do
      "" -> nil
      raw ->
        case Regex.run(~r/(\d{1,3})/, raw) do
          [_, code] -> normalize_code(code)
          _ -> nil
        end
    end
  end

  defp normalize_code(code) do
    code
    |> to_string()
    |> String.trim()
    |> String.pad_leading(3, "0")
  end

  defp blank_row?(row) do
    Enum.all?(row, fn col ->
      col
      |> to_string()
      |> String.trim()
      |> Kernel.==("")
    end)
  end

  defp format_changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
end
