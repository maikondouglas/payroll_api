defmodule PayrollApi.HR.Employee do
  @moduledoc """
  Schema de Funcionário (Employee).
  
  Representa um colaborador da empresa com informações de matrícula e cargo.
  Cada funcionário está associado a exatamente um usuário (1:1).
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias PayrollApi.Accounts.User
  alias PayrollApi.Payroll.Payslip

  schema "employees" do
    field :registration, :string
    field :job_title, :string

    belongs_to :user, User
    has_many :payslips, Payslip, foreign_key: :employee_id, on_delete: :delete_all

    timestamps(type: :utc_datetime)
  end

  @doc """
  Cria um changeset para inserção ou atualização de funcionário.
  """
  def changeset(employee, attrs) do
    employee
    |> cast(attrs, [:registration, :job_title, :user_id])
    |> validate_required([:registration, :job_title, :user_id])
    |> validate_length(:registration, min: 1, max: 20)
    |> validate_length(:job_title, min: 1, max: 100)
    |> unique_constraint(:registration, message: "matrícula já está em uso")
    |> unique_constraint(:user_id, message: "usuário já foi vinculado a outro funcionário")
    |> foreign_key_constraint(:user_id, message: "usuário não existe")
  end
end
