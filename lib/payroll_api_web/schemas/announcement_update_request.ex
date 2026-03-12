defmodule PayrollApiWeb.Schemas.AnnouncementUpdateRequest do
  @moduledoc """
  Schema for announcement update requests.
  """

  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "AnnouncementUpdateRequest",
    description: "Payload to update an announcement",
    type: :object,
    properties: %{
      title: %Schema{type: :string, example: "Updated Health Campaign"},
      content: %Schema{type: :string, example: "Checkups were extended until Friday."},
      category: %Schema{
        type: :string,
        enum: ["health", "training", "company", "events", "system"],
        example: "health"
      },
      published_at: %Schema{type: :string, format: "date-time", example: "2026-03-12T09:00:00Z"},
      expires_at: %Schema{type: :string, format: "date-time", nullable: true},
      is_active: %Schema{type: :boolean, example: true},
      is_pinned: %Schema{type: :boolean, example: true},
      image_url: %Schema{type: :string, nullable: true, example: "https://cdn.example.com/news/health-campaign.png"}
    }
  })
end
