defmodule PayrollApiWeb.V1.UserController do
  use PayrollApiWeb, :controller

  alias PayrollApi.Accounts
  alias PayrollApi.Accounts.User

  action_fallback PayrollApiWeb.FallbackController

  @doc """
  Endpoint protegido que retorna os dados do usuário autenticado.
  O token JWT deve ser enviado no header Authorization: Bearer <token>
  """
  def me(conn, _params) do
    # O Guardian.Plug.LoadResource (configurado no Pipeline)
    # busca o usuário no banco automaticamente e armazena na conexão.
    # Recuperamos o usuário autenticado usando current_resource/1:
    user = PayrollApi.Auth.Guardian.Plug.current_resource(conn)

    conn
    |> put_status(:ok)
    |> json(%{
      "id" => user.id,
      "name" => user.name,
      "cpf" => user.cpf,
      "role" => user.role
    })
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
