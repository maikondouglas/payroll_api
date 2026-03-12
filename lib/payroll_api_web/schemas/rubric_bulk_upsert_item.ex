defmodule PayrollApiWeb.Schemas.RubricBulkUpsertItem do
  @moduledoc """
  Rubric item for bulk import.
  """

  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "RubricBulkUpsertItem",
    type: :object,
    properties: %{
      code: %Schema{type: :string, description: "Rubric code", example: "001"},
      description: %Schema{type: :string, description: "Rubric description", example: "Base Salary"},
      category: %Schema{
        type: :string,
        description: "Rubric category",
        enum: ["earning", "deduction", "base", "charge", "informational"],
        example: "earning"
      }
    },
    required: [:code, :description, :category]
  })
end
