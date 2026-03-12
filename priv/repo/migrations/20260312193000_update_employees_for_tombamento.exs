defmodule PayrollApi.Repo.Migrations.UpdateEmployeesForTombamento do
  use Ecto.Migration

  def change do
    alter table(:employees) do
      add_if_not_exists :job_title, :string, null: false, default: "Not informed"
      add_if_not_exists :admission_date, :date
      add_if_not_exists :birth_date, :date
    end

    create_if_not_exists unique_index(:employees, [:registration])
  end
end
