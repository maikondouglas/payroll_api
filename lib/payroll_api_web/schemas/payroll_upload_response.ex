defmodule PayrollApiWeb.Schemas.PayrollUploadResponse do
  @moduledoc """
  Schema for import endpoint responses.
  """
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "PayrollUploadResponse",
    description: "Import operation result",
    type: :object,
    properties: %{
      message: %Schema{
        type: :string,
        description: "Status message",
        example: "Import completed"
      },
      success: %Schema{
        type: :integer,
        description: "Number of records imported successfully",
        example: 85
      },
      errors: %Schema{
        type: :integer,
        description: "Number of import errors",
        example: 2
      },
      details: %Schema{
        type: :array,
        items: PayrollApiWeb.Schemas.ImportDetail,
        description: "Details for each processed record",
        maxItems: 100
      }
    }
  })
end
