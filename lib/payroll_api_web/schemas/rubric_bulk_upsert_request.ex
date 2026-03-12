defmodule PayrollApiWeb.Schemas.RubricBulkUpsertRequest do
  @moduledoc """
  Schema para importação em lote de rubricas.
  """

  require OpenApiSpex

  OpenApiSpex.schema(%{
    title: "RubricBulkUpsertRequest",
    description: "Lista de rubricas para criação/atualização em lote",
    type: :array,
    items: PayrollApiWeb.Schemas.RubricBulkUpsertItem,
    minItems: 1
  })
end
