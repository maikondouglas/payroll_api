defmodule PayrollApi.Repo.Migrations.CreateRubrics do
  use Ecto.Migration

  def change do
    create table(:rubrics) do
      add :code, :string, null: false
      add :description, :string, null: false
      add :category, :string, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:rubrics, [:code])
  end
end
