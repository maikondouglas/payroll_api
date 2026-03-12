defmodule PayrollApiWeb.Schemas.AnnouncementCreateRequest do
  @moduledoc """
  Schema for announcement create requests.
  """

  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "AnnouncementCreateRequest",
    description: "Payload to create an announcement",
    type: :object,
    properties: %{
      title: %Schema{type: :string, example: "Annual Health Campaign"},
      content: %Schema{type: :string, example: "Free checkups are available this week."},
      category: %Schema{
        type: :string,
        enum: ["health", "training", "company", "events", "system"],
        example: "health"
      },
      published_at: %Schema{type: :string, format: "date-time", example: "2026-03-12T09:00:00Z"},
      expires_at: %Schema{type: :string, format: "date-time", nullable: true},
      is_active: %Schema{type: :boolean, example: true},
      is_pinned: %Schema{type: :boolean, example: false},
      image_url: %Schema{type: :string, nullable: true, example: "https://cdn.example.com/news/health-campaign.png"}
    },
    required: [:title, :content, :category]
  })
end
