defmodule PayrollApi.Repo.Migrations.CreatePayslipItems do
  use Ecto.Migration

  def change do
    create table(:payslip_items) do
      add :reference, :string
      add :amount, :decimal, null: false
      add :payslip_id, references(:payslips, on_delete: :delete_all), null: false
      add :rubric_id, references(:rubrics, on_delete: :nothing), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:payslip_items, [:payslip_id])
    create index(:payslip_items, [:rubric_id])
  end
end
