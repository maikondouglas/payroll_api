defmodule PayrollApiWeb.ApiSpec do
  @moduledoc """
  Especificação OpenAPI para a Payroll API.

  Define a documentação Swagger/OpenAPI completa da API,
  incluindo informações gerais, esquemas de segurança e endpoints.
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
        API RESTful para gerenciamento de folha de pagamento.

        ## Autenticação

        A maioria dos endpoints requer autenticação via token JWT.
        Use o endpoint `/api/v1/login` para obter o token e inclua-o
        no header `Authorization: Bearer {token}` nas requisições protegidas.

        ## Versionamento

        A API está versionada e todas as rotas começam com `/api/v1`.
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
            description: "Token JWT obtido através do endpoint de login"
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
