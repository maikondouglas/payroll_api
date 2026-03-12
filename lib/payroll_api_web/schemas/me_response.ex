defmodule PayrollApiWeb.Schemas.MeResponse do
  @moduledoc """
  Schema for the /me endpoint response.
  """
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "MeResponse",
    description: "Authenticated user data",
    type: :object,
    properties: %{
      id: %Schema{type: :integer, description: "User ID", example: 1},
      name: %Schema{type: :string, description: "User name", example: "Joao Silva"},
      cpf: %Schema{type: :string, description: "User CPF", example: "12345678901"},
      role: %Schema{
        type: :string,
        description: "User role",
        enum: ["admin", "employee"],
        example: "employee"
      }
    }
  })
end
