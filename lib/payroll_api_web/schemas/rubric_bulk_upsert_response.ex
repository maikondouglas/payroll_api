defmodule PayrollApiWeb.Schemas.RubricBulkUpsertResponse do
  @moduledoc """
  Schema for bulk rubric import responses.
  """

  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "RubricBulkUpsertResponse",
    type: :object,
    properties: %{
      message: %Schema{
        type: :string,
        description: "Success message",
        example: "12 rubrics imported or updated successfully"
      },
      count: %Schema{
        type: :integer,
        description: "Number of processed rubrics",
        example: 12
      }
    },
    required: [:message, :count]
  })
end
