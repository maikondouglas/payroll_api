defmodule PayrollApiWeb.Schemas.EmployeeImportRequest do
  @moduledoc """
  Schema para upload de CSV de funcionários.
  """

  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "EmployeeImportRequest",
    description: "Arquivo CSV contendo Matrícula, Nome, Função, Admissão, CPF e Nascimento",
    type: :object,
    properties: %{
      file: %Schema{
        type: :string,
        format: :binary,
        description: "Arquivo CSV de funcionários"
      }
    },
    required: [:file]
  })
end
