defmodule PayrollApiWeb.Schemas.RubricBulkUpsertItem do
  @moduledoc """
  Item de rubrica para importação em lote.
  """

  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "RubricBulkUpsertItem",
    type: :object,
    properties: %{
      code: %Schema{type: :string, description: "Código da rubrica", example: "001"},
      description: %Schema{type: :string, description: "Descrição da rubrica", example: "Salário Base"},
      category: %Schema{
        type: :string,
        description: "Categoria da rubrica",
        enum: ["provento", "desconto"],
        example: "provento"
      }
    },
    required: [:code, :description, :category]
  })
end
