defmodule PayrollApiWeb.V1.SessionController do
  use PayrollApiWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias PayrollApi.Accounts
  alias PayrollApi.Auth.Guardian
  alias PayrollApiWeb.Schemas.{LoginRequest, LoginResponse, ErrorResponse}

  tags ["Autenticação"]

  operation :create,
    summary: "Autenticar usuário via CPF e senha",
    description: "Autentica um usuário fornecendo CPF e senha, retornando um token JWT para usar em requisições autenticadas",
    request_body: {"Credenciais de Login", "application/json", LoginRequest},
    responses: [
      ok: {"Autenticação bem-sucedida", "application/json", LoginResponse},
      unauthorized: {"Credenciais inválidas", "application/json", ErrorResponse},
      bad_request: {"Parâmetros ausentes ou inválidos", "application/json", ErrorResponse}
    ]

  @doc """
  Handler para autenticação de usuários via CPF e senha.

  Espera um JSON com: {"cpf": "...", "password": "..."}

  Retorna 200 OK com token JWT e dados do usuário em caso de sucesso.
  Retorna 401 Unauthorized em caso de credenciais inválidas.
  """
  def create(conn, %{"cpf" => cpf, "password" => password}) do
    case Accounts.authenticate_by_cpf(cpf, password) do
      {:ok, user} ->
        # Gera o token JWT com os dados do usuário
        case Guardian.encode_and_sign(user) do
          {:ok, token, _claims} ->
            conn
            |> put_status(:ok)
            |> render(:show, user: user, token: token)

          {:error, reason} ->
            # Erro ao gerar token (ex: configuração ausente)
            conn
            |> put_status(:internal_server_error)
            |> json(%{"error" => "Erro ao gerar token de autenticação", "details" => inspect(reason)})
        end

      {:error, _reason} ->
        # Retorna erro genérico para não revelar se o CPF existe ou não
        conn
        |> put_status(:unauthorized)
        |> json(%{"error" => "CPF ou senha inválidos"})
    end
  end

  def create(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{"error" => "Parâmetros obrigatórios: cpf e password"})
  end
end
