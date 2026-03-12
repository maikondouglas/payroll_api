defmodule PayrollApiWeb.V1.SessionJSON do
  @moduledoc """
  Renderiza a resposta de autenticação com token JWT e dados do usuário.
  """

  def show(%{user: user, token: token}) do
    %{
      "message" => "Login completed successfully",
      "token" => token,
      "user" => %{
        "id" => user.id,
        "name" => user.name,
        "cpf" => user.cpf,
        "role" => user.role
      }
    }
  end
end
