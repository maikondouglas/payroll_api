defmodule PayrollApi.HR.Employee do
  @moduledoc """
  Schema de Funcionário (Employee).

  Representa um colaborador da empresa com informações de matrícula e cargo.
  Cada funcionário está associado a exatamente um usuário (1:1).
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias PayrollApi.Accounts.User
  alias PayrollApi.Organizations.Department
  alias PayrollApi.Payroll.Payslip

  schema "employees" do
    field :registration, :string
    field :job_title, :string
    field :admission_date, :date
    field :birth_date, :date

    belongs_to :user, User
    belongs_to :department, Department
    has_many :payslips, Payslip, foreign_key: :employee_id, on_delete: :delete_all

    timestamps(type: :utc_datetime)
  end

  @doc """
  Cria um changeset para inserção ou atualização de funcionário.
  """
  def changeset(employee, attrs) do
    employee
    |> cast(attrs, [
      :registration,
      :job_title,
      :admission_date,
      :birth_date,
      :user_id,
      :department_id
    ])
    |> cast_assoc(:user, with: &user_sync_changeset/2)
    |> validate_required([:registration, :job_title, :admission_date, :birth_date, :department_id])
    |> validate_user_reference()
    |> validate_length(:registration, min: 1, max: 20)
    |> validate_length(:job_title, min: 1, max: 100)
    |> unique_constraint(:registration, message: "matrícula já está em uso")
    |> unique_constraint(:user_id, message: "usuário já foi vinculado a outro funcionário")
    |> foreign_key_constraint(:user_id, message: "usuário não existe")
    |> foreign_key_constraint(:department_id, message: "departamento não existe")
  end

  defp validate_user_reference(changeset) do
    user_id = get_field(changeset, :user_id)
    user_change = get_change(changeset, :user)

    if user_id || user_change do
      changeset
    else
      add_error(changeset, :user_id, "deve estar presente")
    end
  end

  # Optional nested user sync for HR workflows.
  # This allows updating name/CPF through Employee without requiring password.
  defp user_sync_changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :cpf])
    |> validate_required([:name, :cpf])
    |> validate_length(:cpf, is: 11, message: "deve conter exatamente 11 dígitos")
    |> unique_constraint(:cpf)
  end
end
