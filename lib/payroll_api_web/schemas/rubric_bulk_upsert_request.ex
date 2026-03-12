defmodule PayrollApiWeb.Schemas.RubricBulkUpsertRequest do
  @moduledoc """
  Schema for bulk rubric import requests.
  """

  require OpenApiSpex

  OpenApiSpex.schema(%{
    title: "RubricBulkUpsertRequest",
    description: "List of rubrics to create or update in bulk",
    type: :array,
    items: PayrollApiWeb.Schemas.RubricBulkUpsertItem,
    minItems: 1
  })
end
