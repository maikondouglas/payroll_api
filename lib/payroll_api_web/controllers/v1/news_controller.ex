defmodule PayrollApiWeb.V1.NewsController do
  use PayrollApiWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias PayrollApi.Communication
  alias PayrollApiWeb.Schemas.AnnouncementListResponse

  tags(["News"])

  operation(:index,
    summary: "List published news",
    description: "Returns active and non-expired announcements for the employee News Board.",
    security: [],
    responses: [
      ok: {"Published announcements", "application/json", AnnouncementListResponse}
    ]
  )

  def index(conn, _params) do
    announcements = Communication.list_published_announcements()

    json(conn, %{data: Enum.map(announcements, &announcement_to_json/1)})
  end

  defp announcement_to_json(announcement) do
    %{
      id: announcement.id,
      title: announcement.title,
      content: announcement.content,
      category: category_to_string(announcement.category),
      published_at: announcement.published_at,
      expires_at: announcement.expires_at,
      is_active: announcement.is_active,
      is_pinned: announcement.is_pinned,
      image_url: announcement.image_url,
      author_id: announcement.author_id,
      inserted_at: announcement.inserted_at,
      updated_at: announcement.updated_at
    }
  end

  defp category_to_string(category) when is_atom(category), do: Atom.to_string(category)
  defp category_to_string(category), do: category
end
