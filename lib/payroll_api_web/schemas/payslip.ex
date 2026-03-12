defmodule PayrollApiWeb.Schemas.Payslip do
  @moduledoc """
  Schema for payslip responses.
  """
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "Payslip",
    description: "Payslip information for an employee",
    type: :object,
    properties: %{
      id: %Schema{type: :integer, description: "Payslip ID", example: 1},
      competence: %Schema{
        type: :string,
        format: :date,
        description: "Competence date",
        example: "2026-01-01"
      },
      base_salary: %Schema{
        type: :string,
        description: "Base salary as a decimal string",
        example: "3000.00"
      },
      net_salary: %Schema{
        type: :string,
        description: "Stored net salary as a decimal string",
        example: "2500.00"
      },
      total_earnings: %Schema{
        type: :string,
        description: "Total earnings as a decimal string",
        example: "1200.00"
      },
      total_deductions: %Schema{
        type: :string,
        description: "Total deductions as a decimal string",
        example: "450.00"
      },
      net_amount: %Schema{
        type: :string,
        description: "Calculated net amount as a decimal string",
        example: "3750.00"
      },
      items: %Schema{
        type: :array,
        description: "Rubric items associated with the payslip",
        items: %Schema{
          type: :object,
          properties: %{
            code: %Schema{type: :string, nullable: true, description: "Rubric code", example: "055"},
            description: %Schema{type: :string, nullable: true, description: "Rubric description", example: "Overtime"},
            category: %Schema{type: :string, nullable: true, description: "Rubric category", example: "earning"},
            reference: %Schema{type: :string, nullable: true, description: "Rubric reference", example: "40h"},
            amount: %Schema{type: :string, description: "Item amount as a decimal string", example: "320.00"}
          }
        }
      },
      employee_id: %Schema{type: :integer, description: "Employee ID", example: 1},
      inserted_at: %Schema{
        type: :string,
        format: "date-time",
        description: "Creation timestamp",
        example: "2026-03-08T10:30:00Z"
      },
      updated_at: %Schema{
        type: :string,
        format: "date-time",
        description: "Last update timestamp",
        example: "2026-03-08T10:30:00Z"
      }
    },
    required: [:id, :competence, :base_salary, :net_salary, :total_earnings, :total_deductions, :net_amount, :items, :employee_id]
  })
end
