defmodule PayrollApiWeb.Schemas.PayslipList do
  @moduledoc """
  Schema for payslip list responses.
  """
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "PayslipList",
    description: "Payslip list",
    type: :object,
    properties: %{
      data: %Schema{
        type: :array,
        items: PayrollApiWeb.Schemas.Payslip,
        description: "Array of payslips"
      }
    }
  })
end
