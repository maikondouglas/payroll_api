defmodule PayrollApiWeb.Schemas.MeResponse do
  @moduledoc """
  Schema for the /me endpoint response.
  """
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "MeResponse",
    description: "Authenticated user data",
    type: :object,
    properties: %{
      id: %Schema{type: :integer, description: "User ID", example: 1},
      name: %Schema{type: :string, description: "User name", example: "Joao Silva"},
      email: %Schema{type: :string, format: :email, description: "User email", example: "joao@empresa.com"},
      cpf: %Schema{type: :string, description: "User CPF", example: "12345678901"},
      role: %Schema{
        type: :string,
        description: "User role",
        enum: ["admin", "employee"],
        example: "employee"
      },
      employee_profile: %Schema{
        type: :object,
        description: "Employee profile data linked to the authenticated user",
        properties: %{
          registration: %Schema{
            type: :string,
            nullable: true,
            description: "Employee registration number",
            example: "EMP-1001"
          },
          job_title: %Schema{
            type: :string,
            nullable: true,
            description: "Employee job title",
            example: "Software Engineer"
          },
          admission_date: %Schema{
            type: :string,
            format: :date,
            nullable: true,
            description: "Employee admission date",
            example: "2024-02-01"
          },
          birth_date: %Schema{
            type: :string,
            format: :date,
            nullable: true,
            description: "Employee birth date",
            example: "1992-08-15"
          }
        },
        required: [:registration, :job_title, :admission_date, :birth_date]
      }
    },
    required: [:id, :name, :email, :cpf, :role, :employee_profile]
  })
end
