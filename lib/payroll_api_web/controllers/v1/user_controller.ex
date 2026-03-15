defmodule PayrollApiWeb.V1.UserController do
  use PayrollApiWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias PayrollApi.Accounts
  alias PayrollApi.Accounts.User
  alias PayrollApiWeb.Schemas.{MeResponse, ErrorResponse}

  action_fallback PayrollApiWeb.FallbackController

  tags(["Users"])

  operation(:me,
    summary: "Get authenticated user",
    description: "Returns the authenticated user information from the JWT token.",
    security: [%{"bearer" => []}],
    responses: [
      ok: {"Authenticated user data", "application/json", MeResponse},
      unauthorized: {"Missing or invalid token", "application/json", ErrorResponse}
    ]
  )

  @doc """
  Endpoint protegido que retorna os dados do usuário autenticado.
  O token JWT deve ser enviado no header Authorization: Bearer <token>
  """
  def me(conn, _params) do
    user = PayrollApi.Auth.Guardian.Plug.current_resource(conn)

    conn
    |> put_status(:ok)
    |> render(:me, user: user)
  end

  def index(conn, _params) do
    users = Accounts.list_users()
    render(conn, :index, users: users)
  end

  def create(conn, %{"user" => user_params}) do
    with {:ok, %User{} = user} <- Accounts.create_user(user_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", "/api/users/#{user.id}")
      |> render(:show, user: user)
    end
  end

  def show(conn, %{"id" => id}) do
    user = Accounts.get_user!(id)
    render(conn, :show, user: user)
  end

  def update(conn, %{"id" => id, "user" => user_params}) do
    user = Accounts.get_user!(id)

    with {:ok, %User{} = user} <- Accounts.update_user(user, user_params) do
      render(conn, :show, user: user)
    end
  end

  def delete(conn, %{"id" => id}) do
    user = Accounts.get_user!(id)

    with {:ok, %User{}} <- Accounts.delete_user(user) do
      send_resp(conn, :no_content, "")
    end
  end
end
