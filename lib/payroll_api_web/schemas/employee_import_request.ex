defmodule PayrollApiWeb.Schemas.EmployeeImportRequest do
  @moduledoc """
  Schema for employee CSV uploads.
  """

  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "EmployeeImportRequest",
    description: "CSV file containing registration, name, job title, hire date, CPF, and birth date",
    type: :object,
    properties: %{
      file: %Schema{
        type: :string,
        format: :binary,
        description: "Employee CSV file"
      }
    },
    required: [:file]
  })
end
