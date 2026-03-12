defmodule PayrollApiWeb.V1.EmployeeImportController do
  use PayrollApiWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias PayrollApi.HR.EmployeeImporter
  alias PayrollApiWeb.Schemas.{EmployeeImportRequest, ErrorResponse, PayrollUploadResponse}

  require Logger

  tags(["RH"])

  operation(:import,
    summary: "Importar funcionarios via CSV",
    description:
      "Faz upload de um CSV de RH para cadastrar ou atualizar funcionários a partir de Matrícula, Nome, Função, Admissão, CPF e Nascimento.",
    security: [%{"bearer" => []}],
    request_body: {"Arquivo CSV", "multipart/form-data", EmployeeImportRequest},
    responses: [
      ok: {"Importacao realizada", "application/json", PayrollUploadResponse},
      bad_request: {"Parametros ausentes, cabeçalho inválido ou CSV malformado", "application/json", ErrorResponse},
      internal_server_error: {"Erro ao processar arquivo", "application/json", ErrorResponse},
      unauthorized: {"Token ausente ou invalido", "application/json", ErrorResponse}
    ]
  )

  def import(conn, %{"file" => %Plug.Upload{path: file_path}}) do
    case EmployeeImporter.import_csv(file_path) do
      {:ok, result} ->
        conn
        |> put_status(:ok)
        |> json(%{
          "message" => "Importacao de funcionarios concluida",
          "success" => result.success,
          "errors" => result.errors,
          "details" => format_details(result.details)
        })

      {:error, reason} ->
        Logger.error("Erro na importacao de funcionarios: #{inspect(reason)}")

        conn
        |> put_status(error_status(reason))
        |> json(%{"error" => "Erro ao processar arquivo", "details" => reason})
    end
  end

  def import(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{"error" => "Parametro obrigatorio: file (arquivo CSV)"})
  end

  defp format_details(details) do
    details
    |> Enum.take(100)
    |> Enum.map(fn
      {:ok, data} -> %{"status" => "success", "data" => data}
      {:error, data} -> %{"status" => "error", "data" => data}
    end)
  end

  defp error_status(%{type: "ConnectionError"}), do: :internal_server_error
  defp error_status(_reason), do: :bad_request
end
