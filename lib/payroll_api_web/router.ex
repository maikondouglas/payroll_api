defmodule PayrollApiWeb.Router do
  use PayrollApiWeb, :router

  # Pipeline padrão para JSON
  pipeline :api do
    plug :accepts, ["json"]
  end

  # Nosso novo pipeline de autenticação
  pipeline :auth do
    plug PayrollApi.Auth.Pipeline
  end

  # --- ROTAS PÚBLICAS ---
  scope "/api", PayrollApiWeb do
    pipe_through :api

    post "/login", SessionController, :create
  end

  # --- ROTAS PROTEGIDAS ---
  scope "/api", PayrollApiWeb do
    pipe_through [:api, :auth] # Aqui exigimos o token!

    # Vamos criar essa rota de teste para ver se funciona:
    get "/me", UserController, :me

    # Upload de folha de pagamento
    post "/payroll/upload", PayrollController, :upload

    # Contracheques do colaborador autenticado
    get "/my-payslips", MyPayslipController, :index
    get "/my-payslips/:id", MyPayslipController, :show
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
