defmodule PayrollApiWeb.ApiSpec do
  @moduledoc """
  OpenAPI specification for Payroll API.

  Defines the full Swagger/OpenAPI documentation for the API,
  including general information, security schemes, and endpoints.
  """

  alias OpenApiSpex.{Info, OpenApi, Paths, Server, Components, SecurityScheme}
  alias PayrollApiWeb.{Endpoint, Router}
  @behaviour OpenApi

  @impl OpenApi
  def spec do
    %OpenApi{
      info: %Info{
        title: "Payroll API",
        version: "1.0.0",
        description: """
        RESTful API for payroll management.

        ## Authentication

        Most endpoints require JWT authentication.
        Use `/api/v1/login` to obtain a token and include it
        in the `Authorization: Bearer {token}` header for protected requests.

        ## Versioning

        The API is versioned and all routes start with `/api/v1`.
        """
      },
      servers: [
        Server.from_endpoint(Endpoint)
      ],
      paths: Paths.from_router(Router),
      components: %Components{
        securitySchemes: %{
          "bearer" => %SecurityScheme{
            type: "http",
            scheme: "bearer",
            bearerFormat: "JWT",
            description: "JWT token obtained from the login endpoint"
          }
        }
      },
      security: [
        %{"bearer" => []}
      ]
    }
    |> OpenApiSpex.resolve_schema_modules()
  end
end
