defmodule PayrollApi.Auth.Guardian do
  @moduledoc """
  Implementação do Guardian para geração e validação de tokens JWT.
  """

  use Guardian, otp_app: :payroll_api

  alias PayrollApi.Accounts

  @doc """
  Converte o usuário em um subject (identificador) para o token JWT.
  O subject é armazenado na claim "sub" do token.
  """
  def subject_for_token(user, _claims) do
    {:ok, to_string(user.id)}
  end

  @doc """
  Recupera o usuário a partir das claims do token JWT.
  Esta função é chamada quando precisamos carregar o recurso do token.
  """
  def resource_from_claims(claims) do
    id = claims["sub"]
    resource = Accounts.get_user!(id)
    {:ok, resource}
  rescue
    Ecto.NoResultsError ->
      {:error, :resource_not_found}
  end
end
