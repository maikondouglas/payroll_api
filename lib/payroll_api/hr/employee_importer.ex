NimbleCSV.define(PayrollApi.HR.CSVSemicolon, separator: ";", escape: "\"")

defmodule PayrollApi.HR.EmployeeImporter do
  @moduledoc """
  Importador de dados mestres (funcionarios).

  Responsavel por cadastrar/atualizar User + Employee a partir do CSV
  detalhado de RH.
  """

  import Ecto.Query, warn: false

  alias Ecto.Multi
  alias NimbleCSV.RFC4180
  alias PayrollApi.Accounts.User
  alias PayrollApi.HR.Employee
  alias PayrollApi.Repo

  @default_password "Mudar123!"

  def import_csv(file_path) do
    Multi.new()
    |> Multi.run(:csv_data, fn _repo, _ -> read_csv(file_path) end)
    |> Multi.run(:import, fn repo, %{csv_data: {headers, rows, col_map, header_line}} ->
      import_rows(repo, headers, rows, col_map, header_line)
    end)
    |> Repo.transaction(timeout: :infinity, pool_timeout: 60_000)
    |> case do
      {:ok, %{import: result}} -> {:ok, result}
      {:error, _step, reason, _changes} -> {:error, reason}
    end
  rescue
    _e in File.Error -> {:error, "Arquivo CSV nao encontrado ou inacessivel"}
    e -> {:error, %{message: "Erro ao importar funcionarios", exception: Exception.message(e), type: e.__struct__ |> Module.split() |> List.last()}}
  end

  defp read_csv(file_path) do
    parser = detect_parser(file_path)

    rows =
      file_path
      |> File.stream!()
      |> parser.parse_stream(skip_headers: false)
      |> Enum.to_list()

    case find_header_row(rows) do
      {:ok, header_index, headers, col_map} ->
        {:ok, {headers, Enum.drop(rows, header_index + 1), col_map, header_index + 1}}

      :error ->
        {:error, "Cabecalho CSV invalido para importacao de funcionarios"}
    end
  end

  defp detect_parser(file_path) do
    first_line = file_path |> File.stream!() |> Enum.take(1) |> List.first("")

    if count_occurrences(first_line, ";") > count_occurrences(first_line, ",") do
      PayrollApi.HR.CSVSemicolon
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

  defp find_header_row(rows) do
    rows
    |> Enum.with_index()
    |> Enum.find_value(:error, fn {row, index} ->
      case identify_columns(row) do
        {:ok, col_map} -> {:ok, index, row, col_map}
        :error -> false
      end
    end)
  end

  defp identify_columns(headers) do
    normalized = Enum.map(headers, &normalize_header/1)

    col_map = %{
      matricula: find_column(normalized, ["matr"]),
      nome: find_column(normalized, ["nome"]),
      cpf: find_column(normalized, ["cpf"]),
      funcao: find_column(normalized, ["funcao", "cargo"]),
      admissao: find_column(normalized, ["admissao"]),
      nascimento: find_column(normalized, ["nascimento"])
    }

    if col_map.matricula && col_map.nome && col_map.cpf do
      {:ok, col_map}
    else
      :error
    end
  end

  defp find_column(headers, tokens) do
    Enum.find_index(headers, fn header -> Enum.all?(tokens, &String.contains?(header, &1)) end)
  end

  defp import_rows(repo, _headers, rows, col_map, header_line) do
    rows
    |> Enum.with_index(header_line + 1)
    |> Enum.reduce_while({:ok, %{success: 0, errors: 0, details: []}}, fn {row, line_number}, {:ok, acc} ->
      if blank_row?(row) do
        {:cont, {:ok, acc}}
      else
        case import_row(repo, row, col_map, line_number) do
          {:ok, detail} ->
            next = %{acc | success: acc.success + 1, details: [{:ok, detail} | acc.details]}
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

  defp import_row(repo, row, col_map, line_number) do
    with {:ok, registration} <- extract_required(row, col_map.matricula, "Matricula"),
         {:ok, name} <- extract_required(row, col_map.nome, "Nome"),
         {:ok, cpf} <- extract_cpf(row, col_map.cpf),
         {:ok, employee} <-
           find_or_create_or_update_employee(repo, %{
             registration: registration,
             name: name,
             cpf: cpf,
             job_title: extract_optional(row, col_map.funcao),
             admission_date: parse_date(extract_optional(row, col_map.admissao)),
             birth_date: parse_date(extract_optional(row, col_map.nascimento))
           }) do
      {:ok, %{line: line_number, employee_id: employee.id, registration: employee.registration, cpf: cpf, name: name}}
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        {:error, %{message: "Falha ao salvar funcionario na linha #{line_number}", details: format_changeset_errors(changeset)}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp find_or_create_or_update_employee(repo, data) do
    case find_employee_by_registration_or_cpf(repo, data.registration, data.cpf) do
      nil ->
        with {:ok, user} <- create_user(repo, data),
             {:ok, employee} <- create_employee(repo, user.id, data) do
          {:ok, employee}
        end

      %Employee{} = employee ->
        update_existing_employee(repo, employee, data)
    end
  end

  defp find_employee_by_registration_or_cpf(repo, registration, cpf) do
    query =
      from e in Employee,
        left_join: u in assoc(e, :user),
        where: e.registration == ^registration or u.cpf == ^cpf,
        preload: [:user],
        limit: 1

    repo.one(query)
  end

  defp create_user(repo, data) do
    attrs = %{
      name: data.name,
      cpf: data.cpf,
      email: "#{data.cpf}@importacao.com",
      role: "employee",
      password: @default_password
    }

    case repo.insert(User.changeset(%User{}, attrs)) do
      {:ok, user} -> {:ok, user}
      {:error, changeset} -> {:error, changeset}
    end
  end

  defp create_employee(repo, user_id, data) do
    attrs =
      %{
        user_id: user_id,
        registration: data.registration,
        job_title: blank_to_default(data.job_title, "Nao informado")
      }
      |> maybe_put_employee_date(:admission_date, data.admission_date)
      |> maybe_put_employee_date(:birth_date, data.birth_date)

    repo.insert(Employee.changeset(%Employee{}, attrs))
  end

  defp update_existing_employee(repo, %Employee{} = employee, data) do
    with {:ok, _user} <- update_employee_user(repo, employee.user, data),
         {:ok, updated_employee} <- update_employee(repo, employee, data) do
      {:ok, updated_employee}
    end
  end

  defp update_employee_user(repo, nil, data) do
    with {:ok, user} <- create_user(repo, data),
         {:ok, _employee} <- employee_assign_user(repo, data.registration, user.id) do
      {:ok, user}
    end
  end

  defp update_employee_user(repo, %User{} = user, data) do
    attrs = %{
      name: data.name,
      cpf: data.cpf,
      email: "#{data.cpf}@importacao.com",
      role: user.role || "employee",
      password: @default_password
    }

    repo.update(User.changeset(user, attrs))
  end

  defp employee_assign_user(repo, registration, user_id) do
    case repo.get_by(Employee, registration: registration) do
      nil -> {:error, "Funcionario nao encontrado para vincular usuario"}
      employee -> repo.update(Ecto.Changeset.change(employee, user_id: user_id))
    end
  end

  defp update_employee(repo, employee, data) do
    attrs =
      %{
        registration: data.registration,
        job_title: blank_to_default(data.job_title, "Nao informado")
      }
      |> maybe_put_employee_date(:admission_date, data.admission_date)
      |> maybe_put_employee_date(:birth_date, data.birth_date)

    repo.update(Employee.changeset(employee, Map.put(attrs, :user_id, employee.user_id)))
  end

  defp maybe_put_employee_date(attrs, field, value) do
    if field in Employee.__schema__(:fields) and value do
      Map.put(attrs, field, value)
    else
      attrs
    end
  end

  defp extract_required(row, index, label) do
    case extract_optional(row, index) do
      nil -> {:error, "#{label} vazio"}
      value -> {:ok, value}
    end
  end

  defp extract_cpf(row, index) do
    with {:ok, raw_cpf} <- extract_required(row, index, "CPF") do
      cleaned = String.replace(raw_cpf, ~r/\D/u, "")
      if String.length(cleaned) == 11, do: {:ok, cleaned}, else: {:error, "CPF invalido: #{raw_cpf}"}
    end
  end

  defp extract_optional(_row, nil), do: nil

  defp extract_optional(row, index) do
    row
    |> Enum.at(index)
    |> to_string()
    |> String.trim()
    |> case do
      "" -> nil
      value -> value
    end
  end

  defp parse_date(nil), do: nil

  defp parse_date(date_str) do
    parts = date_str |> String.trim() |> String.split(~r{[/-]}, trim: true)

    with [p1, p2, p3] <- parts,
         {n1, ""} <- Integer.parse(p1),
         {n2, ""} <- Integer.parse(p2),
         {year, ""} <- Integer.parse(p3),
         {month, day} <- infer_month_day(n1, n2),
         {:ok, date} <- Date.new(year, month, day) do
      date
    else
      _ -> nil
    end
  end

  defp infer_month_day(n1, n2) when n1 > 12, do: {n2, n1}
  defp infer_month_day(n1, n2) when n2 > 12, do: {n1, n2}
  defp infer_month_day(n1, n2), do: {n2, n1}

  defp normalize_header(value) do
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

  defp blank_row?(row) do
    Enum.all?(row, fn col -> col |> to_string() |> String.trim() |> Kernel.==("") end)
  end

  defp blank_to_default(nil, default), do: default
  defp blank_to_default(value, default), do: if(String.trim(value) == "", do: default, else: String.trim(value))

  defp format_changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
end
