defmodule PayrollApiWeb.Schemas.RubricBulkUpsertResponse do
  @moduledoc """
  Schema de resposta para importação em lote de rubricas.
  """

  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "RubricBulkUpsertResponse",
    type: :object,
    properties: %{
      message: %Schema{
        type: :string,
        description: "Mensagem de sucesso",
        example: "12 rubricas importadas/atualizadas com sucesso!"
      },
      count: %Schema{
        type: :integer,
        description: "Quantidade de rubricas processadas",
        example: 12
      }
    },
    required: [:message, :count]
  })
end
