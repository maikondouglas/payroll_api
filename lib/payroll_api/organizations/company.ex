defmodule PayrollApi.Organizations.Company do
  @moduledoc """
  Company entity used to group departments and employees.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias PayrollApi.Organizations.Department

  schema "companies" do
    field :name, :string
    field :cnpj, :string
    field :is_active, :boolean, default: true

    has_many :departments, Department, on_delete: :delete_all

    timestamps(type: :utc_datetime)
  end

  def changeset(company, attrs) do
    company
    |> cast(attrs, [:name, :cnpj, :is_active])
    |> validate_required([:name, :is_active])
    |> validate_length(:name, min: 1, max: 255)
    |> unique_constraint(:name)
  end
end
