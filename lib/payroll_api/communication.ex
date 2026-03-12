defmodule PayrollApi.Communication do
  @moduledoc """
  The Communication context.
  """

  import Ecto.Query, warn: false

  alias PayrollApi.Communication.Announcement
  alias PayrollApi.Repo

  @doc """
  Returns all announcements.
  """
  def list_announcements do
    Announcement
    |> order_by([a], desc: a.published_at)
    |> Repo.all()
  end

  @doc """
  Returns all published announcements for the News Board.

  Criteria:
  - `is_active == true`
  - `expires_at` is null OR greater than current UTC datetime

  Ordering:
  - pinned first (`is_pinned == true`)
  - then `published_at` descending
  """
  def list_published_announcements do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    Announcement
    |> where([a], a.is_active == true)
    |> where([a], is_nil(a.expires_at) or a.expires_at > ^now)
    |> order_by([a], desc: a.is_pinned, desc: a.published_at)
    |> Repo.all()
  end

  @doc """
  Gets a single announcement.

  Raises `Ecto.NoResultsError` if the announcement does not exist.
  """
  def get_announcement!(id), do: Repo.get!(Announcement, id)

  @doc """
  Creates an announcement.
  """
  def create_announcement(attrs \\ %{}) do
    %Announcement{}
    |> Announcement.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates an announcement.
  """
  def update_announcement(%Announcement{} = announcement, attrs) do
    announcement
    |> Announcement.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes an announcement.
  """
  def delete_announcement(%Announcement{} = announcement) do
    Repo.delete(announcement)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking announcement changes.
  """
  def change_announcement(%Announcement{} = announcement, attrs \\ %{}) do
    Announcement.changeset(announcement, attrs)
  end
end
