defmodule PayrollApi.Payroll.Importer do
  @moduledoc """
  Módulo para importação de dados de folha de pagamento via CSV.
  
  Cria automaticamente usuários e funcionários caso não existam,
  utilizando Ecto.Multi para garantir atomicidade das operações.
  """

  import Ecto.Query, warn: false
  alias NimbleCSV.RFC4180, as: CSV
  alias PayrollApi.{Repo, Accounts, HR, Payroll}
  alias Ecto.Multi

  require Logger

  @doc """
  Importa um arquivo CSV de folha de pagamento criando registros de Payslip.

  Para cada linha do CSV, o processo:
  1. Busca ou cria o User por CPF
  2. Busca ou cria o Employee por matrícula
  3. Cria o Payslip

  Tudo é feito em uma transação atômica usando Ecto.Multi.

  ## Parâmetros
    * `file_path` - Caminho do arquivo CSV
    * `competence_date` - Data de competência (mês/ano) no formato ~D[2024-01-01]

  ## Estrutura do CSV
  Matrícula,CPF,Nome,Salário Contratual,Função,Salário Líquido,Salário Base,GRATIFICAÇÃO COMPLEMENTAR,...

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
      "CPF",
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

  # Processa uma linha individual do CSV usando Ecto.Multi
  defp process_row(row, headers, competence_date) do
    # Extrai os dados da linha
    with {:ok, row_data} <- extract_row_data(row, headers) do
      # Cria o Multi para transação atômica
      Multi.new()
      |> Multi.run(:user, fn _repo, _changes ->
        find_or_create_user(row_data.cpf, row_data.name)
      end)
      |> Multi.run(:employee, fn _repo, %{user: user} ->
        find_or_create_employee(row_data.registration, row_data.job_title, user.id)
      end)
      |> Multi.run(:payslip, fn _repo, %{employee: employee} ->
        create_payslip(
          employee.id,
          competence_date,
          row_data.base_salary,
          row_data.net_salary,
          row_data.details
        )
      end)
      |> Repo.transaction()
      |> case do
        {:ok, %{payslip: payslip}} ->
          Logger.debug(
            "Payslip criado para matrícula #{row_data.registration} (CPF: #{row_data.cpf})"
          )

          {:ok,
           %{
             registration: row_data.registration,
             cpf: row_data.cpf,
             name: row_data.name,
             payslip_id: payslip.id
           }}

        {:error, :user, changeset, _changes} ->
          errors = format_changeset_errors(changeset)
          Logger.warning("Erro ao criar/buscar usuário: #{inspect(errors)}")

          {:error,
           %{
             registration: row_data.registration,
             cpf: row_data.cpf,
             reason: "Erro ao criar usuário",
             details: errors
           }}

        {:error, :employee, changeset, _changes} ->
          errors = format_changeset_errors(changeset)
          Logger.warning("Erro ao criar/buscar funcionário: #{inspect(errors)}")

          {:error,
           %{
             registration: row_data.registration,
             cpf: row_data.cpf,
             reason: "Erro ao criar funcionário",
             details: errors
           }}

        {:error, :payslip, changeset, _changes} ->
          errors = format_changeset_errors(changeset)
          Logger.warning("Erro ao criar payslip: #{inspect(errors)}")

          {:error,
           %{
             registration: row_data.registration,
             cpf: row_data.cpf,
             reason: "Erro ao criar contracheque",
             details: errors
           }}

        {:error, step, reason, _changes} ->
          Logger.error("Erro no passo #{step}: #{inspect(reason)}")

          {:error,
           %{
             registration: row_data.registration,
             cpf: row_data.cpf,
             reason: "Erro na transação: #{step}",
             details: inspect(reason)
           }}
      end
    else
      {:error, reason} ->
        Logger.warning("Erro ao extrair dados da linha: #{inspect(reason)}")
        {:error, %{registration: Enum.at(row, 0), cpf: Enum.at(row, 1), reason: reason}}
    end
  end

  # Extrai e valida todos os dados da linha do CSV
  defp extract_row_data(row, headers) do
    with {:ok, registration} <- extract_field(row, 0, "Matrícula"),
         {:ok, cpf} <- extract_cpf(row, 1),
         {:ok, name} <- extract_field(row, 2, "Nome"),
         {:ok, job_title} <- extract_field(row, 4, "Função"),
         {:ok, net_salary} <- parse_decimal(Enum.at(row, 5)),
         {:ok, base_salary} <- parse_decimal(Enum.at(row, 6)),
         {:ok, details} <- build_details_map(row, headers) do
      {:ok,
       %{
         registration: registration,
         cpf: cpf,
         name: name,
         job_title: job_title,
         net_salary: net_salary,
         base_salary: base_salary,
         details: details
       }}
    end
  end

  # Extrai e valida um campo genérico
  defp extract_field(row, index, field_name) do
    case Enum.at(row, index) do
      nil -> {:error, "#{field_name} vazio"}
      "" -> {:error, "#{field_name} vazio"}
      value -> {:ok, String.trim(value)}
    end
  end

  # Extrai e limpa o CPF (remove pontuação)
  defp extract_cpf(row, index) do
    case Enum.at(row, index) do
      nil ->
        {:error, "CPF vazio"}

      "" ->
        {:error, "CPF vazio"}

      cpf ->
        # Remove pontuação do CPF (pontos, hífens, espaços)
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

  # Busca ou cria um usuário por CPF
  defp find_or_create_user(cpf, name) do
    case Accounts.get_user_by_cpf(cpf) do
      nil ->
        # Cria novo usuário com email baseado no CPF
        attrs = %{
          name: name,
          cpf: cpf,
          email: "#{cpf}@sistema.com",
          password: "Muda@123",
          role: "employee"
        }

        case Accounts.create_user(attrs) do
          {:ok, user} ->
            Logger.info("Usuário criado: CPF #{cpf}")
            {:ok, user}

          {:error, changeset} ->
            {:error, changeset}
        end

      user ->
        Logger.debug("Usuário encontrado: CPF #{cpf}")
        {:ok, user}
    end
  end

  # Busca ou cria um funcionário por matrícula
  defp find_or_create_employee(registration, job_title, user_id) do
    case HR.get_employee_by_registration(registration) do
      nil ->
        # Cria novo funcionário
        attrs = %{
          registration: registration,
          job_title: job_title,
          user_id: user_id
        }

        case HR.create_employee(attrs) do
          {:ok, employee} ->
            Logger.info("Funcionário criado: matrícula #{registration}")
            {:ok, employee}

          {:error, changeset} ->
            {:error, changeset}
        end

      employee ->
        Logger.debug("Funcionário encontrado: matrícula #{registration}")
        {:ok, employee}
    end
  end

  # Cria um payslip
  defp create_payslip(employee_id, competence_date, base_salary, net_salary, details) do
    attrs = %{
      employee_id: employee_id,
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
        # Ex: 1.621,00 vira 1621,00
        |> String.replace(".", "")
        # Ex: 1621,00 vira 1621.00
        |> String.replace(",", ".")
      else
        # Se já for "1621" ou "1621.00", mantém intacto
        cleaned_value
      end

    case Decimal.parse(final_value) do
      {decimal, _} -> {:ok, decimal}
      :error -> {:error, "Valor decimal inválido: #{value}"}
    end
  end

  # Constrói o mapa de detalhes com todas as rubricas
  defp build_details_map(row, headers) do
    # Índices das rubricas extras (a partir da coluna 7)
    # Colunas: Matrícula(0), CPF(1), Nome(2), Salário Contratual(3), Função(4), 
    # Salário Líquido(5), Salário Base(6), Rubricas(7+)
    details =
      headers
      |> Enum.drop(7)
      |> Enum.with_index(7)
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

  # Formata erros do changeset para log
  defp format_changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
end
