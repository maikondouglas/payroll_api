defmodule PayrollApiWeb.Schemas.LoginResponse do
  @moduledoc """
  Schema para resposta de login bem-sucedido.
  """
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "LoginResponse",
    description: "Resposta de autenticação com token JWT e dados do usuário",
    type: :object,
    properties: %{
      token: %Schema{
        type: :string,
        description: "Token JWT para autenticação",
        example: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
      },
      user: %Schema{
        type: :object,
        properties: %{
          id: %Schema{type: :integer, description: "ID do usuário", example: 1},
          name: %Schema{type: :string, description: "Nome do usuário", example: "João Silva"},
          cpf: %Schema{type: :string, description: "CPF do usuário", example: "12345678901"},
          role: %Schema{
            type: :string,
            description: "Papel do usuário no sistema",
            enum: ["admin", "employee"],
            example: "employee"
          }
        }
      }
    },
    example: %{
      "token" => "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxIn0...",
      "user" => %{
        "id" => 1,
        "name" => "João Silva",
        "cpf" => "12345678901",
        "role" => "employee"
      }
    }
  })
end
