defmodule PayrollApiWeb.Schemas.PayslipList do
  @moduledoc """
  Schema para lista de contracheques.
  """
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "PayslipList",
    description: "Lista de contracheques",
    type: :object,
    properties: %{
      data: %Schema{
        type: :array,
        items: PayrollApiWeb.Schemas.Payslip,
        description: "Array de contracheques"
      }
    }
  })
end
