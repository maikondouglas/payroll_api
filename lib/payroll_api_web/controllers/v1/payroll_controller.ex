defmodule PayrollApiWeb.V1.PayrollController do
  use PayrollApiWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias PayrollApi.Payroll.Importer
  alias PayrollApiWeb.Schemas.{PayrollUploadResponse, ErrorResponse}

  require Logger

  tags ["Folha de Pagamento"]

  operation :upload,
    summary: "Importar folha de pagamento via CSV",
    description: "Faz upload de um arquivo CSV com dados de folha de pagamento e importa os registros",
    security: [%{"bearer" => []}],
    request_body: {"Arquivo CSV", "multipart/form-data", PayrollApiWeb.Schemas.PayrollUploadRequest},
    responses: [
      ok: {"Importação realizada", "application/json", PayrollUploadResponse},
      bad_request: {"Parâmetros ausentes ou inválidos", "application/json", ErrorResponse},
      internal_server_error: {"Erro ao processar arquivo", "application/json", ErrorResponse},
      unauthorized: {"Token ausente ou inválido", "application/json", ErrorResponse}
    ]

  @doc """
  Endpoint para upload e importação de arquivo CSV de folha de pagamento.

  Espera receber:
  - "file": arquivo CSV via multipart/form-data
  - "competence": string de data no formato ISO8601 (ex: "2026-01-01")

  Retorna 200 OK com resultado da importação em caso de sucesso.
  Retorna 400 Bad Request se parâmetros estiverem ausentes ou inválidos.
  Retorna 500 Internal Server Error se houver erro na importação.
  """
  def upload(conn, %{"file" => %Plug.Upload{path: file_path}, "competence" => competence_str}) do
    case parse_competence(competence_str) do
      {:ok, competence_date} ->
        case Importer.import_csv(file_path, competence_date) do
          {:ok, result} ->
            conn
            |> put_status(:ok)
            |> json(%{
              "message" => "Importação concluída",
              "success" => result.success,
              "errors" => result.errors,
              "details" => format_details(result.details)
            })

          {:error, reason} ->
            Logger.error("Erro na importação: #{inspect(reason)}")

            conn
            |> put_status(:internal_server_error)
            |> json(%{"error" => "Erro ao processar arquivo", "details" => reason})
        end

      {:error, :invalid_date} ->
        conn
        |> put_status(:bad_request)
        |> json(%{"error" => "Data de competência inválida. Use formato ISO8601 (ex: 2026-01-01)"})
    end
  end

  def upload(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{
      "error" => "Parâmetros obrigatórios",
      "required" => %{
        "file" => "arquivo CSV (.csv)",
        "competence" => "data de competência (formato: YYYY-MM-DD)"
      }
    })
  end

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
end
