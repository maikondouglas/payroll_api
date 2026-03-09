defmodule PayrollApiWeb.Schemas.PayrollUploadResponse do
  @moduledoc """
  Schema para resposta de upload de folha de pagamento.
  """
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "PayrollUploadResponse",
    description: "Resultado da importação de folha de pagamento",
    type: :object,
    properties: %{
      message: %Schema{
        type: :string,
        description: "Mensagem de status",
        example: "Importação concluída"
      },
      success: %Schema{
        type: :integer,
        description: "Quantidade de registros importados com sucesso",
        example: 85
      },
      errors: %Schema{
        type: :integer,
        description: "Quantidade de erros na importação",
        example: 2
      },
      details: %Schema{
        type: :array,
        items: PayrollApiWeb.Schemas.ImportDetail,
        description: "Detalhes de cada registro processado",
        maxItems: 100
      }
    }
  })
end
