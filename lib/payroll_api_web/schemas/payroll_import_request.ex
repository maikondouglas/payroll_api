defmodule PayrollApiWeb.Schemas.PayrollImportRequest do
  @moduledoc """
  Schema para upload de CSV transacional da folha.
  """

  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "PayrollImportRequest",
    description: "Arquivo CSV transacional contendo matrícula e códigos de rubricas. Requer também a competência da folha.",
    type: :object,
    properties: %{
      file: %Schema{
        type: :string,
        format: :binary,
        description: "Arquivo CSV de folha transacional"
      },
      competence: %Schema{
        type: :string,
        format: :date,
        description: "Data de competência da folha (YYYY-MM-DD)",
        example: "2026-02-01"
      }
    },
    required: [:file, :competence]
  })
end
