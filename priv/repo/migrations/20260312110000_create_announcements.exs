defmodule PayrollApi.Repo.Migrations.CreateAnnouncements do
  use Ecto.Migration

  def change do
    create table(:announcements) do
      add :title, :string, null: false
      add :content, :text, null: false
      add :category, :string, null: false
      add :published_at, :utc_datetime, null: false
      add :expires_at, :utc_datetime
      add :is_active, :boolean, default: true, null: false
      add :is_pinned, :boolean, default: false, null: false
      add :image_url, :string
      add :author_id, references(:users, on_delete: :nothing), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:announcements, [:author_id])
    create index(:announcements, [:is_active, :is_pinned, :published_at])
    create index(:announcements, [:expires_at])

    create constraint(:announcements, :category_must_be_valid,
             check: "category IN ('health', 'training', 'company', 'events', 'system')"
           )
  end
end
