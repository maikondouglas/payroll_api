defmodule PayrollApi.Repo.Migrations.CreateEmployees do
  use Ecto.Migration

  def change do
    create table(:employees) do
      add :registration, :string, null: false
      add :job_title, :string, null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    # Índice único para registration
    create unique_index(:employees, [:registration])

    # Índice único para user_id (relação 1:1)
    create unique_index(:employees, [:user_id])
  end
end
