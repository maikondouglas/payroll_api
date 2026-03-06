defmodule PayrollApi.Repo.Migrations.CreatePayslips do
  use Ecto.Migration

  def change do
    create table(:payslips) do
      add :competence, :date, null: false
      add :base_salary, :decimal, precision: 10, scale: 2, null: false
      add :net_salary, :decimal, precision: 10, scale: 2, null: false
      add :details, :map, null: false, default: %{}
      add :employee_id, references(:employees, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    # Índice composto para unicidade de competence por employee
    create unique_index(:payslips, [:employee_id, :competence])

    # Índice para facilitar queries por employee_id
    create index(:payslips, [:employee_id])

    # Índice para facilitar queries por competence
    create index(:payslips, [:competence])
  end
end
