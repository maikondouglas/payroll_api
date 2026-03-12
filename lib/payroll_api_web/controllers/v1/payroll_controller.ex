defmodule PayrollApiWeb.V1.PayrollController do
  use PayrollApiWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias PayrollApi.Payroll.Importer
  alias PayrollApiWeb.Schemas.{ErrorResponse, PayrollImportRequest, PayrollUploadResponse}

  require Logger

  tags(["Payroll"])

  operation(:import,
    summary: "Import payroll data from CSV",
    description:
      "Uploads a transactional CSV file containing employee registration and rubric codes to import payroll financial entries.",
    security: [%{"bearer" => []}],
    request_body: {"CSV file", "multipart/form-data", PayrollImportRequest},
    responses: [
      ok: {"Import completed", "application/json", PayrollUploadResponse},
      bad_request: {"Missing parameters, invalid CSV, or unknown registration", "application/json", ErrorResponse},
      internal_server_error: {"Failed to process file", "application/json", ErrorResponse},
      unauthorized: {"Missing or invalid token", "application/json", ErrorResponse}
    ]
  )

  @doc """
  Endpoint para upload e importação de arquivo CSV de folha de pagamento.

  Espera receber:
  - "file": arquivo CSV via multipart/form-data
  - "competence": string de data no formato ISO8601 (ex: "2026-01-01")

  Retorna 200 OK com resultado da importação em caso de sucesso.
  Retorna 400 Bad Request se parâmetros estiverem ausentes ou inválidos.
  Retorna 500 Internal Server Error se houver erro na importação.
  """
  def import(conn, %{"file" => %Plug.Upload{path: file_path}, "competence" => competence_str}) do
    case parse_competence(competence_str) do
      {:ok, competence_date} ->
        case Importer.import_csv(file_path, competence_date) do
          {:ok, result} ->
            conn
            |> put_status(:ok)
            |> json(%{
              "message" => "Import completed",
              "success" => result.success,
              "errors" => result.errors,
              "details" => format_details(result.details)
            })

          {:error, reason} ->
            Logger.error("Payroll import failed: #{inspect(reason)}")

            conn
            |> put_status(error_status(reason))
            |> json(%{"error" => "Failed to process file", "details" => reason})
        end

      {:error, :invalid_date} ->
        conn
        |> put_status(:bad_request)
        |> json(%{"error" => "Invalid competence date. Use ISO8601 format (example: 2026-01-01)"})
    end
  end

  def import(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{
      "error" => "Missing required parameters",
      "required" => %{
        "file" => "CSV file (.csv)",
        "competence" => "payroll competence date (format: YYYY-MM-DD)"
      }
    })
  end

  # Compatibilidade com rota antiga /payroll/upload
  def upload(conn, params), do: __MODULE__.import(conn, params)

  # Converte string de data para Date
  defp parse_competence(competence_str) when is_binary(competence_str) do
    case Date.from_iso8601(competence_str) do
      {:ok, date} -> {:ok, date}
      {:error, _} -> {:error, :invalid_date}
    end
  end

  defp parse_competence(_), do: {:error, :invalid_date}

  # Formata os detalhes para resposta JSON (limita quantidade de detalhes)
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
