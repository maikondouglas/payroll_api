defmodule PayrollApi.Auth.ErrorHandler do
  import Plug.Conn

  @behaviour Guardian.Plug.ErrorHandler

  @impl Guardian.Plug.ErrorHandler
  def auth_error(conn, {type, _reason}, _opts) do
    # Converte o erro para JSON
    body =
      Jason.encode!(%{
        error: "Acesso negado. Token ausente ou inválido.",
        details: to_string(type)
      })

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(401, body)
  end
end
