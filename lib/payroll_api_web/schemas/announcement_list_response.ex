defmodule PayrollApiWeb.Schemas.AnnouncementListResponse do
  @moduledoc """
  Schema for announcement list responses.
  """

  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "AnnouncementListResponse",
    description: "List of announcements",
    type: :object,
    properties: %{
      data: %Schema{
        type: :array,
        items: %Schema{
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
            expires_at: %Schema{type: :string, format: "date-time", nullable: true},
            is_active: %Schema{type: :boolean, example: true},
            is_pinned: %Schema{type: :boolean, example: false},
            image_url: %Schema{type: :string, nullable: true},
            author_id: %Schema{type: :integer, example: 1},
            inserted_at: %Schema{type: :string, format: "date-time"},
            updated_at: %Schema{type: :string, format: "date-time"}
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
        },
        description: "Announcement collection"
      }
    },
    required: [:data]
  })
end
