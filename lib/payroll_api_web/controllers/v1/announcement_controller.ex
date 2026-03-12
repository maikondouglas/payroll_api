defmodule PayrollApiWeb.V1.AnnouncementController do
  use PayrollApiWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias PayrollApi.Auth.Guardian
  alias PayrollApi.Communication
  alias PayrollApi.Communication.Announcement

  alias PayrollApiWeb.Schemas.{
    AnnouncementCreateRequest,
    AnnouncementListResponse,
    AnnouncementResponse,
    AnnouncementUpdateRequest,
    ErrorResponse
  }

  action_fallback PayrollApiWeb.FallbackController

  tags(["Announcements"])

  operation(:index,
    summary: "List announcements",
    description: "Returns all announcements for administrative management.",
    security: [%{"bearer" => []}],
    responses: [
      ok: {"Announcement list", "application/json", AnnouncementListResponse},
      unauthorized: {"Missing or invalid token", "application/json", ErrorResponse}
    ]
  )

  operation(:show,
    summary: "Get announcement",
    description: "Returns a specific announcement by ID.",
    security: [%{"bearer" => []}],
    parameters: [
      id: [in: :path, description: "Announcement ID", schema: %OpenApiSpex.Schema{type: :integer}, required: true]
    ],
    responses: [
      ok: {"Announcement", "application/json", AnnouncementResponse},
      not_found: {"Announcement not found", "application/json", ErrorResponse},
      unauthorized: {"Missing or invalid token", "application/json", ErrorResponse}
    ]
  )

  operation(:create,
    summary: "Create announcement",
    description: "Creates an announcement. The author is always taken from the authenticated user.",
    security: [%{"bearer" => []}],
    request_body: {"Announcement payload", "application/json", AnnouncementCreateRequest},
    responses: [
      created: {"Announcement created", "application/json", AnnouncementResponse},
      unprocessable_entity: {"Validation error", "application/json", ErrorResponse},
      unauthorized: {"Missing or invalid token", "application/json", ErrorResponse}
    ]
  )

  operation(:update,
    summary: "Update announcement",
    description: "Updates an announcement by ID.",
    security: [%{"bearer" => []}],
    parameters: [
      id: [in: :path, description: "Announcement ID", schema: %OpenApiSpex.Schema{type: :integer}, required: true]
    ],
    request_body: {"Announcement payload", "application/json", AnnouncementUpdateRequest},
    responses: [
      ok: {"Announcement updated", "application/json", AnnouncementResponse},
      not_found: {"Announcement not found", "application/json", ErrorResponse},
      unprocessable_entity: {"Validation error", "application/json", ErrorResponse},
      unauthorized: {"Missing or invalid token", "application/json", ErrorResponse}
    ]
  )

  operation(:delete,
    summary: "Delete announcement",
    description: "Deletes an announcement by ID.",
    security: [%{"bearer" => []}],
    parameters: [
      id: [in: :path, description: "Announcement ID", schema: %OpenApiSpex.Schema{type: :integer}, required: true]
    ],
    responses: [
      no_content: {"Announcement deleted", nil, nil},
      not_found: {"Announcement not found", "application/json", ErrorResponse},
      unauthorized: {"Missing or invalid token", "application/json", ErrorResponse}
    ]
  )

  def index(conn, _params) do
    announcements = Communication.list_announcements()
    json(conn, %{data: Enum.map(announcements, &announcement_to_json/1)})
  end

  def show(conn, %{"id" => id}) do
    announcement = Communication.get_announcement!(id)
    json(conn, %{data: announcement_to_json(announcement)})
  end

  def create(conn, params) do
    current_user = Guardian.Plug.current_resource(conn)

    attrs =
      params
      |> extract_payload()
      |> Map.put("author_id", current_user.id)
      |> Map.delete("author")

    with {:ok, %Announcement{} = announcement} <- Communication.create_announcement(attrs) do
      conn
      |> put_status(:created)
      |> json(%{data: announcement_to_json(announcement)})
    end
  end

  def update(conn, %{"id" => id} = params) do
    announcement = Communication.get_announcement!(id)

    attrs =
      params
      |> extract_payload()
      |> Map.delete("author_id")
      |> Map.delete("author")

    with {:ok, %Announcement{} = announcement} <- Communication.update_announcement(announcement, attrs) do
      json(conn, %{data: announcement_to_json(announcement)})
    end
  end

  def delete(conn, %{"id" => id}) do
    announcement = Communication.get_announcement!(id)

    with {:ok, %Announcement{}} <- Communication.delete_announcement(announcement) do
      send_resp(conn, :no_content, "")
    end
  end

  defp extract_payload(%{"announcement" => attrs}) when is_map(attrs), do: attrs
  defp extract_payload(params) when is_map(params), do: Map.drop(params, ["id"])

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
