defmodule PayrollApiWeb.Schemas.ErrorResponse do
  @moduledoc """
  Schema for standard API error responses.
  """
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "ErrorResponse",
    description: "Standard API error response",
    type: :object,
    properties: %{
      error: %Schema{
        type: :string,
        description: "Error message",
        example: "Invalid CPF or password"
      },
      details: %Schema{
        description: "Additional error details (optional)",
        nullable: true,
        oneOf: [
          %Schema{type: :string, example: "Invalid CSV header"},
          %Schema{type: :object, additionalProperties: true},
          %Schema{type: :array, items: %Schema{type: :object, additionalProperties: true}}
        ]
      }
    },
    required: [:error]
  })
end
