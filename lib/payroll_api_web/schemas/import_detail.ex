defmodule PayrollApiWeb.Schemas.ImportDetail do
  @moduledoc """
  Schema para detalhe de importação (sucesso ou erro).
  """
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "ImportDetail",
    description: "Resultado de importação de uma linha",
    type: :object,
    properties: %{
      status: %Schema{
        type: :string,
        enum: ["success", "error"],
        description: "Status da importação",
        example: "success"
      },
      data: %Schema{
        type: :object,
        description: "Dados do resultado (sucesso ou erro)"
      }
    }
  })
end
