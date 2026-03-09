defmodule PayrollApiWeb.Schemas.MeResponse do
  @moduledoc """
  Schema para resposta do endpoint /me.
  """
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "MeResponse",
    description: "Dados do usuário autenticado",
    type: :object,
    properties: %{
      id: %Schema{type: :integer, description: "ID do usuário", example: 1},
      name: %Schema{type: :string, description: "Nome do usuário", example: "João Silva"},
      cpf: %Schema{type: :string, description: "CPF do usuário", example: "12345678901"},
      role: %Schema{
        type: :string,
        description: "Papel do usuário",
        enum: ["admin", "employee"],
        example: "employee"
      }
    }
  })
end
