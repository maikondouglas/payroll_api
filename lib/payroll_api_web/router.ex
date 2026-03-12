defmodule PayrollApiWeb.Router do
  use PayrollApiWeb, :router

  # Pipeline padrão para JSON
  pipeline :api do
    plug :accepts, ["json"]
    plug OpenApiSpex.Plug.PutApiSpec, module: PayrollApiWeb.ApiSpec
  end

  # Nosso novo pipeline de autenticação
  pipeline :auth do
    plug PayrollApi.Auth.Pipeline
  end

  pipeline :admin do
    plug PayrollApiWeb.Plugs.RequireAdmin
  end

  # --- ROTAS V1 ---
  scope "/api/v1", PayrollApiWeb.V1, as: :v1 do
    pipe_through :api

    # Rotas públicas
    post "/login", SessionController, :create
    get "/news", NewsController, :index

    # Rotas protegidas
    scope "/" do
      pipe_through :auth

      get "/me", UserController, :me
      post "/hr/employees/import", EmployeeImportController, :import
      post "/payroll/import", PayrollController, :import
      post "/payroll/upload", PayrollController, :upload

      # Contracheques do colaborador
      get "/my-payslips", MyPayslipController, :index
      get "/my-payslips/:id", MyPayslipController, :show
      get "/my-payslips/:id/download", MyPayslipController, :download
    end

    scope "/" do
      pipe_through [:auth, :admin]

      resources "/announcements", AnnouncementController, except: [:new, :edit]
      resources "/rubrics", RubricController, except: [:new, :edit]
    end
  end

  # --- OPENAPI/SWAGGER ---
  scope "/api" do
    pipe_through :api

    get "/openapi", OpenApiSpex.Plug.RenderSpec, []
  end

  scope "/api" do
    pipe_through :api

    get "/swagger", OpenApiSpex.Plug.SwaggerUI, path: "/api/openapi"
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:payroll_api, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through [:fetch_session, :protect_from_forgery]

      live_dashboard "/dashboard", metrics: PayrollApiWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
