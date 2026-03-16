defmodule PayrollApi.Organizations.Department do
  @moduledoc """
  Department entity linked to a company.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias PayrollApi.HR.Employee
  alias PayrollApi.Organizations.Company

  schema "departments" do
    field :name, :string
    field :is_active, :boolean, default: true

    belongs_to :company, Company
    has_many :employees, Employee, foreign_key: :department_id

    timestamps(type: :utc_datetime)
  end

  def changeset(department, attrs) do
    department
    |> cast(attrs, [:name, :is_active, :company_id])
    |> validate_required([:name, :is_active, :company_id])
    |> validate_length(:name, min: 1, max: 255)
    |> unique_constraint(:name, name: :departments_company_id_name_index)
    |> foreign_key_constraint(:company_id)
  end
end
