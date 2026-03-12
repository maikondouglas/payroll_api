defmodule PayrollApi.Communication.Announcement do
  @moduledoc """
  Announcement schema used by the News Board.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias PayrollApi.Accounts.User

  @categories [:health, :training, :company, :events, :system]

  schema "announcements" do
    field :title, :string
    field :content, :string
    field :category, Ecto.Enum, values: @categories
    field :published_at, :utc_datetime
    field :expires_at, :utc_datetime
    field :is_active, :boolean, default: true
    field :is_pinned, :boolean, default: false
    field :image_url, :string

    belongs_to :author, User, foreign_key: :author_id

    timestamps(type: :utc_datetime)
  end

  @doc """
  Creates a changeset for announcement create/update operations.
  """
  def changeset(announcement, attrs) do
    announcement
    |> cast(attrs, [
      :title,
      :content,
      :category,
      :published_at,
      :expires_at,
      :is_active,
      :is_pinned,
      :image_url,
      :author_id
    ])
    |> put_default_published_at()
    |> validate_required([:title, :content, :category, :published_at, :author_id])
    |> validate_length(:title, min: 3, max: 180)
    |> validate_length(:content, min: 3)
    |> validate_format(:image_url, ~r/^https?:\/\//,
      message: "must start with http:// or https://"
    )
    |> validate_expiration_after_publication()
    |> foreign_key_constraint(:author_id)
  end

  def categories, do: @categories

  defp put_default_published_at(changeset) do
    case get_field(changeset, :published_at) do
      nil -> put_change(changeset, :published_at, DateTime.utc_now() |> DateTime.truncate(:second))
      _ -> changeset
    end
  end

  defp validate_expiration_after_publication(changeset) do
    published_at = get_field(changeset, :published_at)
    expires_at = get_field(changeset, :expires_at)

    if is_struct(published_at, DateTime) and is_struct(expires_at, DateTime) and
         DateTime.compare(expires_at, published_at) != :gt do
      add_error(changeset, :expires_at, "must be greater than published_at")
    else
      changeset
    end
  end
end
