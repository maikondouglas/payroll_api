defmodule PayrollApi.Repo.Migrations.CreateCompaniesAndDepartments do
  use Ecto.Migration

  def change do
    create table(:companies) do
      add :name, :string, null: false
      add :cnpj, :string
      add :is_active, :boolean, null: false, default: true

      timestamps(type: :utc_datetime)
    end

    create unique_index(:companies, [:name])

    create table(:departments) do
      add :name, :string, null: false
      add :is_active, :boolean, null: false, default: true
      add :company_id, references(:companies, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:departments, [:company_id])
    create unique_index(:departments, [:company_id, :name])
  end
end
