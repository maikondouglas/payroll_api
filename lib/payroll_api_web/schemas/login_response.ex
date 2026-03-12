defmodule PayrollApiWeb.Schemas.LoginResponse do
  @moduledoc """
  Schema for successful login responses.
  """
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "LoginResponse",
    description: "Authentication response with JWT token and user data",
    type: :object,
    properties: %{
      message: %Schema{
        type: :string,
        description: "Success message",
        example: "Login completed successfully"
      },
      token: %Schema{
        type: :string,
        description: "JWT token for authentication",
        example: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
      },
      user: %Schema{
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
      }
    },
    example: %{
      "message" => "Login completed successfully",
      "token" => "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxIn0...",
      "user" => %{
        "id" => 1,
        "name" => "Joao Silva",
        "cpf" => "12345678901",
        "role" => "employee"
      }
    }
  })
end
