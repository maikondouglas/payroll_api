defmodule PayrollApi.Auth.Pipeline do
  use Guardian.Plug.Pipeline,
    otp_app: :payroll_api,
    error_handler: PayrollApi.Auth.ErrorHandler,
    module: PayrollApi.Auth.Guardian

  # 1. Procura o token no cabeçalho "Authorization: Bearer <TOKEN>"
  plug Guardian.Plug.VerifyHeader, scheme: "Bearer"

  # 2. Garante que um token válido foi encontrado (se não, chama o ErrorHandler)
  plug Guardian.Plug.EnsureAuthenticated

  # 3. Pega o ID que está dentro do token e busca o usuário no banco de dados
  plug Guardian.Plug.LoadResource
end
