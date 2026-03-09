defmodule PayrollApiWeb.Schemas.PayrollUploadRequest do
  @moduledoc """
  Schema para requisição de upload de folha de pagamento.
  """
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "PayrollUploadRequest",
    description: "Arquivo CSV e data de competência para importação",
    type: :object,
    properties: %{
      file: %Schema{
        type: :string,
        format: :binary,
        description: "Arquivo CSV com dados de folha de pagamento"
      },
      competence: %Schema{
        type: :string,
        format: :date,
        description: "Data de competência (formato ISO8601: YYYY-MM-DD)",
        example: "2026-01-01"
      }
    },
    required: [:file, :competence]
  })
end
