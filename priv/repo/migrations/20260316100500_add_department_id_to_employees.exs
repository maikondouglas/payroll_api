defmodule PayrollApi.Repo.Migrations.AddDepartmentIdToEmployees do
  use Ecto.Migration

  def up do
    alter table(:employees) do
      add :department_id, references(:departments, on_delete: :restrict)
    end

    create index(:employees, [:department_id])

    execute("""
    INSERT INTO companies (name, is_active, inserted_at, updated_at)
    VALUES ('Default Company', TRUE, NOW(), NOW())
    ON CONFLICT (name) DO NOTHING
    """)

    execute("""
    INSERT INTO departments (name, company_id, is_active, inserted_at, updated_at)
    SELECT 'General', c.id, TRUE, NOW(), NOW()
    FROM companies c
    WHERE c.name = 'Default Company'
    ON CONFLICT (company_id, name) DO NOTHING
    """)

    execute("""
    UPDATE employees e
    SET department_id = d.id
    FROM departments d
    JOIN companies c ON c.id = d.company_id
    WHERE c.name = 'Default Company'
      AND d.name = 'General'
      AND e.department_id IS NULL
    """)

    execute("ALTER TABLE employees ALTER COLUMN department_id SET NOT NULL")
  end

  def down do
    execute("ALTER TABLE employees ALTER COLUMN department_id DROP NOT NULL")

    alter table(:employees) do
      remove :department_id
    end

    drop_if_exists index(:employees, [:department_id])
  end
end
