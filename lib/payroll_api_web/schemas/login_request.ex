defmodule PayrollApiWeb.Schemas.LoginRequest do
  @moduledoc """
  Schema para requisição de login.
  """
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "LoginRequest",
    description: "Credenciais de login (CPF e senha)",
    type: :object,
    properties: %{
      cpf: %Schema{
        type: :string,
        description: "CPF do usuário (11 dígitos, sem pontuação)",
        pattern: "^[0-9]{11}$",
        example: "12345678901"
      },
      password: %Schema{
        type: :string,
        description: "Senha do usuário",
        format: :password,
        example: "Senha@123"
      }
    },
    required: [:cpf, :password],
    example: %{
      "cpf" => "12345678901",
      "password" => "Senha@123"
    }
  })
end
