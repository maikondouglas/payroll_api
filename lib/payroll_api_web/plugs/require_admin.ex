defmodule PayrollApiWeb.Plugs.RequireAdmin do
  @moduledoc """
  Garante que apenas usuários administradores acessem a rota.
  """

  import Plug.Conn
  import Phoenix.Controller, only: [json: 2]

  alias PayrollApi.Auth.Guardian

  def init(opts), do: opts

  def call(conn, _opts) do
    user = Guardian.Plug.current_resource(conn)

    if admin?(user) do
      conn
    else
      conn
      |> put_status(:forbidden)
      |> json(%{"error" => "Acesso negado. Apenas administradores podem acessar este recurso."})
      |> halt()
    end
  end

  defp admin?(nil), do: false

  defp admin?(user) do
    Map.get(user, :role) == "admin" or Map.get(user, :is_admin, false) == true
  end
end
