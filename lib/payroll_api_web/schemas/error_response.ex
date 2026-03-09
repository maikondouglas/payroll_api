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
        type: :string,
        description: "Detalhes adicionais do erro (opcional)"
      }
    },
    required: [:error]
  })
end
