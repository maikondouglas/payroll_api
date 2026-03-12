defmodule PayrollApiWeb.Schemas.AnnouncementResponse do
  @moduledoc """
  Schema for announcement responses.
  """

  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "AnnouncementResponse",
    description: "Announcement payload",
    type: :object,
    properties: %{
      data: %Schema{
        type: :object,
        properties: %{
          id: %Schema{type: :integer, example: 12},
          title: %Schema{type: :string, example: "Annual Health Campaign"},
          content: %Schema{type: :string, example: "Free checkups are available this week."},
          category: %Schema{
            type: :string,
            enum: ["health", "training", "company", "events", "system"],
            example: "health"
          },
          published_at: %Schema{type: :string, format: "date-time", example: "2026-03-12T09:00:00Z"},
          expires_at: %Schema{
            type: :string,
            format: "date-time",
            nullable: true,
            example: "2026-03-20T23:59:59Z"
          },
          is_active: %Schema{type: :boolean, example: true},
          is_pinned: %Schema{type: :boolean, example: false},
          image_url: %Schema{
            type: :string,
            nullable: true,
            example: "https://cdn.example.com/news/health-campaign.png"
          },
          author_id: %Schema{type: :integer, example: 1},
          inserted_at: %Schema{type: :string, format: "date-time", example: "2026-03-12T09:00:00Z"},
          updated_at: %Schema{type: :string, format: "date-time", example: "2026-03-12T09:00:00Z"}
        },
        required: [
          :id,
          :title,
          :content,
          :category,
          :published_at,
          :is_active,
          :is_pinned,
          :author_id
        ]
      }
    },
    required: [:data]
  })
end
