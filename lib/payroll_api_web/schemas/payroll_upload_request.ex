defmodule PayrollApiWeb.Schemas.PayrollUploadRequest do
  @moduledoc """
  Schema for legacy payroll upload requests.
  """
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "PayrollUploadRequest",
    description: "CSV file and competence date for import",
    type: :object,
    properties: %{
      file: %Schema{
        type: :string,
        format: :binary,
        description: "CSV file with payroll data"
      },
      competence: %Schema{
        type: :string,
        format: :date,
        description: "Competence date (ISO8601 format: YYYY-MM-DD)",
        example: "2026-01-01"
      }
    },
    required: [:file, :competence]
  })
end
