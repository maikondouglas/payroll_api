defmodule PayrollApiWeb.Schemas.Payslip do
  @moduledoc """
  Schema para contracheque (payslip).
  """
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "Payslip",
    description: "Informações do contracheque de um funcionário",
    type: :object,
    properties: %{
      id: %Schema{type: :integer, description: "ID do contracheque", example: 1},
      competence: %Schema{
        type: :string,
        format: :date,
        description: "Data de competência (mês/ano)",
        example: "2026-01-01"
      },
      base_salary: %Schema{
        type: :string,
        description: "Salário base em Decimal (string)",
        example: "3000.00"
      },
      net_salary: %Schema{
        type: :string,
        description: "Salário líquido em Decimal (string)",
        example: "2500.00"
      },
      employee_id: %Schema{type: :integer, description: "ID do funcionário", example: 1},
      details: %Schema{
        type: :object,
        description: "Detalhes de rubricas (mapa dinâmico)",
        example: %{
          "INSS Folha" => "150.00",
          "Adicional Noturno" => "200.00"
        }
      },
      inserted_at: %Schema{
        type: :string,
        format: "date-time",
        description: "Data de criação",
        example: "2026-03-08T10:30:00Z"
      },
      updated_at: %Schema{
        type: :string,
        format: "date-time",
        description: "Data de última atualização",
        example: "2026-03-08T10:30:00Z"
      }
    }
  })
end
