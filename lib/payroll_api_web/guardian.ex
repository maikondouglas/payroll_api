defmodule PayrollApiWeb.Guardian do
  use Guardian, otp_app: :payroll_api

  alias PayrollApi.Accounts

  def subject_for_token(user, _claims) do
    {:ok, to_string(user.id)}
  end

  def resource_from_claims(claims) do
    id = claims["sub"]
    resource = Accounts.get_user!(id)
    {:ok, resource}
  rescue
    Ecto.NoResultsError ->
      {:error, :resource_not_found}
  end
end
