defmodule PayrollApiWeb.Schemas.PayrollImportRequest do
  @moduledoc """
  Schema for transactional payroll CSV uploads.
  """

  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "PayrollImportRequest",
    description: "Transactional CSV file containing employee registration and rubric codes. Also requires the payroll competence date.",
    type: :object,
    properties: %{
      file: %Schema{
        type: :string,
        format: :binary,
        description: "Transactional payroll CSV file"
      },
      competence: %Schema{
        type: :string,
        format: :date,
        description: "Payroll competence date (YYYY-MM-DD)",
        example: "2026-02-01"
      }
    },
    required: [:file, :competence]
  })
end
