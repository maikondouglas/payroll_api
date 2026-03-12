defmodule PayrollApiWeb.V1.EmployeeImportController do
  use PayrollApiWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias PayrollApi.HR.EmployeeImporter
  alias PayrollApiWeb.Schemas.{EmployeeImportRequest, ErrorResponse, PayrollUploadResponse}

  require Logger

  tags(["HR"])

  operation(:import,
    summary: "Import employees from CSV",
    description:
      "Uploads an HR CSV file to create or update employees using registration, name, job title, hire date, CPF, and birth date.",
    security: [%{"bearer" => []}],
    request_body: {"CSV file", "multipart/form-data", EmployeeImportRequest},
    responses: [
      ok: {"Import completed", "application/json", PayrollUploadResponse},
      bad_request: {"Missing parameters, invalid header, or malformed CSV", "application/json", ErrorResponse},
      internal_server_error: {"Failed to process file", "application/json", ErrorResponse},
      unauthorized: {"Missing or invalid token", "application/json", ErrorResponse}
    ]
  )

  def import(conn, %{"file" => %Plug.Upload{path: file_path}}) do
    case EmployeeImporter.import_csv(file_path) do
      {:ok, result} ->
        conn
        |> put_status(:ok)
        |> json(%{
          "message" => "Employee import completed",
          "success" => result.success,
          "errors" => result.errors,
          "details" => format_details(result.details)
        })

      {:error, reason} ->
        Logger.error("Employee import failed: #{inspect(reason)}")

        conn
        |> put_status(error_status(reason))
        |> json(%{"error" => "Failed to process file", "details" => reason})
    end
  end

  def import(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{"error" => "Required parameter: file (CSV file)"})
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
