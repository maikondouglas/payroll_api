defmodule PayrollApi.Repo do
  use Ecto.Repo,
    otp_app: :payroll_api,
    adapter: Ecto.Adapters.Postgres
end
