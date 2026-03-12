defmodule PayrollApiWeb.Schemas.ImportDetail do
  @moduledoc """
  Schema for import row details.
  """
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "ImportDetail",
    description: "Import result for a single row",
    type: :object,
    properties: %{
      status: %Schema{
        type: :string,
        enum: ["success", "error"],
        description: "Import status",
        example: "success"
      },
      data: %Schema{
        allOf: [PayrollApiWeb.Schemas.EmployeeImportData],
        description: "Result payload for the processed row"
      }
    }
  })
end
