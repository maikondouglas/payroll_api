defmodule PayrollApiWeb.Schemas.EmployeeImportData do
  @moduledoc """
  Schema for successful employee import row payload.
  """
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "EmployeeImportData",
    description: "Employee data returned for a successfully processed import row",
    type: :object,
    properties: %{
      line: %Schema{type: :integer, description: "CSV line number", example: 2},
      employee_id: %Schema{type: :integer, description: "Employee ID", example: 1},
      registration: %Schema{type: :string, description: "Employee registration", example: "12345"},
      name: %Schema{type: :string, description: "Employee name", example: "John Doe"},
      cpf: %Schema{type: :string, description: "Employee CPF", example: "00011122233"},
      job_title: %Schema{type: :string, description: "Employee job title", example: "Nurse"},
      admission_date: %Schema{type: :string, format: :date, description: "Admission date", example: "2026-01-15"},
      birth_date: %Schema{type: :string, format: :date, description: "Birth date", example: "1990-03-20"}
    },
    required: [:line, :employee_id, :registration, :name, :cpf, :job_title],
    additionalProperties: true
  })
end
