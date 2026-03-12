defmodule PayrollApiWeb.Schemas.ErrorResponse do
  @moduledoc """
  Schema para resposta de erro.
  """
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "ErrorResponse",
    description: "Resposta de erro padrão da API",
    type: :object,
    properties: %{
      error: %Schema{
        type: :string,
        description: "Mensagem de erro",
        example: "CPF ou senha inválidos"
      },
      details: %Schema{
        description: "Detalhes adicionais do erro (opcional)",
        nullable: true,
        oneOf: [
          %Schema{type: :string, example: "Cabeçalho CSV inválido"},
          %Schema{type: :object, additionalProperties: true},
          %Schema{type: :array, items: %Schema{type: :object, additionalProperties: true}}
        ]
      }
    },
    required: [:error]
  })
end
