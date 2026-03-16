#!/usr/bin/env elixir

unless Code.ensure_loaded?(NimbleCSV) do
  Mix.install([{:nimble_csv, "~> 1.3"}])
end

NimbleCSV.define(CSVSemicolon, separator: ";", escape: "\"")

defmodule SplitCSV do
  alias NimbleCSV.RFC4180

  @employees_header [
    "matricula",
    "nome",
    "empresa",
    "setor",
    "funcao",
    "admissao",
    "cpf",
    "nascimento"
  ]

  def run([input_path]) do
    with {:ok, {headers, rows}} <- read_csv(input_path),
         {:ok, master_indexes} <- find_master_indexes(headers),
         {:ok, financial_columns} <- find_financial_columns(headers) do
      employees_rows = build_employees_rows(rows, master_indexes)
      payroll_rows = build_payroll_rows(rows, master_indexes.matricula, financial_columns)

      base_dir = Path.dirname(input_path)
      employees_path = Path.join(base_dir, "employees.csv")
      payroll_path = Path.join(base_dir, "payroll.csv")

      write_csv(employees_path, [@employees_header | employees_rows])

      write_csv(payroll_path, [
        ["matricula" | Enum.map(financial_columns, &elem(&1, 0))] | payroll_rows
      ])

      IO.puts("OK: employees.csv gerado em #{employees_path} (#{length(employees_rows)} linhas)")
      IO.puts("OK: payroll.csv gerado em #{payroll_path} (#{length(payroll_rows)} linhas)")
      :ok
    else
      {:error, reason} ->
        IO.puts(:stderr, "Erro: #{reason}")
        System.halt(1)
    end
  end

  def run(_args) do
    IO.puts(:stderr, "Uso: elixir split_csv.exs <arquivo.csv>")
    System.halt(1)
  end

  defp read_csv(input_path) do
    parser = detect_parser(input_path)

    rows =
      input_path
      |> File.stream!()
      |> parser.parse_stream(skip_headers: false)
      |> Enum.to_list()

    case rows do
      [] ->
        {:error, "Arquivo CSV vazio"}

      [headers | data_rows] ->
        {:ok, {headers, Enum.reject(data_rows, &blank_row?/1)}}
    end
  rescue
    e in File.Error -> {:error, Exception.message(e)}
  end

  defp detect_parser(input_path) do
    first_line =
      input_path
      |> File.stream!()
      |> Enum.find("", fn line -> String.trim(line) != "" end)

    if count_occurrences(first_line, ";") > count_occurrences(first_line, ",") do
      CSVSemicolon
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

  defp find_master_indexes(headers) do
    normalized = Enum.map(headers, &normalize/1)

    indexes = %{
      matricula: find_column(normalized, ["matr"]),
      nome: find_column(normalized, ["nome"]),
      empresa: find_column(normalized, ["empresa"]) || find_column(normalized, ["company"]),
      setor:
        find_column(normalized, ["setor"]) || find_column(normalized, ["departamento"]) ||
          find_column(normalized, ["department"]),
      funcao: find_column(normalized, ["funcao"]) || find_column(normalized, ["cargo"]),
      admissao: find_column(normalized, ["admissao"]),
      cpf: find_column(normalized, ["cpf"]),
      nascimento: find_column(normalized, ["nascimento"])
    }

    required = [:matricula, :nome, :cpf, :empresa, :setor]

    if Enum.all?(required, &(Map.get(indexes, &1) != nil)) do
      {:ok, indexes}
    else
      {:error,
       "Nao foi possivel localizar as colunas minimas de dados mestres (matricula, nome, cpf, empresa, setor/departamento)"}
    end
  end

  defp find_financial_columns(headers) do
    cols =
      headers
      |> Enum.with_index()
      |> Enum.reduce([], fn {header, index}, acc ->
        case extract_rubric_code(header) do
          nil -> acc
          code -> [{code, index} | acc]
        end
      end)
      |> Enum.reverse()
      |> Enum.reduce([], fn {code, index}, acc ->
        case List.keyfind(acc, code, 0) do
          nil -> [{code, [index]} | acc]
          {^code, indexes} -> List.keyreplace(acc, code, 0, {code, indexes ++ [index]})
        end
      end)
      |> Enum.reverse()

    if cols == [] do
      {:error, "Nenhuma coluna financeira (rubrica) foi encontrada"}
    else
      {:ok, cols}
    end
  end

  defp build_employees_rows(rows, indexes) do
    Enum.map(rows, fn row ->
      [
        at(row, indexes.matricula),
        at(row, indexes.nome),
        at(row, indexes.empresa),
        at(row, indexes.setor),
        at(row, indexes.funcao),
        at(row, indexes.admissao),
        at(row, indexes.cpf),
        at(row, indexes.nascimento)
      ]
    end)
  end

  defp build_payroll_rows(rows, matricula_index, financial_columns) do
    Enum.map(rows, fn row ->
      [
        at(row, matricula_index)
        | Enum.map(financial_columns, fn {_code, indexes} ->
            indexes
            |> Enum.map(&at(row, &1))
            |> sum_money_values()
          end)
      ]
    end)
  end

  defp sum_money_values(values) do
    total =
      Enum.reduce(values, 0.0, fn value, acc ->
        acc + parse_money(value)
      end)

    format_money(total)
  end

  defp parse_money(nil), do: 0.0

  defp parse_money(value) do
    normalized =
      value
      |> to_string()
      |> String.replace(~r/[[:space:]]/u, "")
      |> String.replace("R$", "")
      |> String.trim()
      |> normalize_decimal_string()

    case Float.parse(normalized) do
      {number, _} -> number
      :error -> 0.0
    end
  end

  defp normalize_decimal_string(value) do
    has_dot = String.contains?(value, ".")
    has_comma = String.contains?(value, ",")

    cond do
      value == "" ->
        "0"

      has_dot and has_comma ->
        if last_separator_index(value, ",") > last_separator_index(value, ".") do
          value |> String.replace(".", "") |> String.replace(",", ".")
        else
          String.replace(value, ",", "")
        end

      has_comma ->
        case Regex.run(~r/,\d{1,2}$/u, value) do
          nil -> String.replace(value, ",", "")
          _ -> String.replace(value, ",", ".")
        end

      true ->
        value
    end
  end

  defp last_separator_index(value, separator) do
    case :binary.matches(value, separator) do
      [] ->
        -1

      matches ->
        {index, _len} = List.last(matches)
        index
    end
  end

  defp format_money(number) do
    "R$ " <> :erlang.float_to_binary(number, decimals: 2)
  end

  defp at(_row, nil), do: ""
  defp at(row, index), do: Enum.at(row, index, "")

  defp blank_row?(row) do
    Enum.all?(row, fn value -> String.trim(to_string(value)) == "" end)
  end

  defp find_column(headers, tokens) do
    Enum.find_index(headers, fn header ->
      Enum.all?(tokens, &String.contains?(header, &1))
    end)
  end

  defp extract_rubric_code(header) do
    case Regex.run(~r/^\s*(\d{1,3})\b/u, to_string(header)) do
      [_, code] -> String.pad_leading(code, 3, "0")
      _ -> nil
    end
  end

  defp normalize(value) do
    value
    |> to_string()
    |> String.replace_prefix("\uFEFF", "")
    |> String.downcase()
    |> String.normalize(:nfd)
    |> String.replace(~r/[\p{Mn}]/u, "")
    |> String.replace(~r/[^\p{L}\p{N}]+/u, " ")
    |> String.replace(~r/\s+/u, " ")
    |> String.trim()
  end

  defp write_csv(path, rows) do
    content = RFC4180.dump_to_iodata(rows)
    File.write!(path, content)
  end
end

SplitCSV.run(System.argv())
