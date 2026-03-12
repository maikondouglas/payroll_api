defmodule PayrollApiWeb.Schemas.LoginRequest do
  @moduledoc """
  Schema for login requests.
  """
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "LoginRequest",
    description: "Login credentials (CPF and password)",
    type: :object,
    properties: %{
      cpf: %Schema{
        type: :string,
        description: "User CPF (11 digits, no punctuation)",
        pattern: "^[0-9]{11}$",
        example: "12345678901"
      },
      password: %Schema{
        type: :string,
        description: "User password",
        format: :password,
        example: "Password@123"
      }
    },
    required: [:cpf, :password],
    example: %{
      "cpf" => "12345678901",
      "password" => "Password@123"
    }
  })
end
