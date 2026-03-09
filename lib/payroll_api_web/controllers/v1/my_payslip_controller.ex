defmodule PayrollApiWeb.V1.MyPayslipController do
  use PayrollApiWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias PayrollApi.Payroll
  alias PayrollApi.Auth.Guardian
  alias PayrollApiWeb.Schemas.{PayslipList, Payslip, ErrorResponse}

  action_fallback PayrollApiWeb.FallbackController

  tags ["Contracheques"]

  operation :index,
    summary: "Listar contracheques do usuário",
    description: "Retorna todos os contracheques do usuário autenticado, ordenados por competência (mais recente primeiro)",
    security: [%{"bearer" => []}],
    responses: [
      ok: {"Lista de contracheques", "application/json", PayslipList},
      unauthorized: {"Token ausente ou inválido", "application/json", ErrorResponse}
    ]

  operation :show,
    summary: "Obter contracheque específico",
    description: "Retorna um contracheque específico do usuário autenticado, incluindo detalhes de rubricas",
    security: [%{"bearer" => []}],
    parameters: [
      id: [
        in: :path,
        description: "ID do contracheque",
        schema: %OpenApiSpex.Schema{type: :integer},
        required: true
      ]
    ],
    responses: [
      ok: {"Contracheque encontrado", "application/json", Payslip},
      not_found: {"Contracheque não encontrado", "application/json", ErrorResponse},
      unauthorized: {"Token ausente ou inválido", "application/json", ErrorResponse}
    ]

  @doc """
  Retorna a lista de contracheques do usuário autenticado.

  O token JWT deve ser enviado no header Authorization: Bearer <token>
  Retorna os contracheques ordenados por competência decrescente.
  """
  def index(conn, _params) do
    user = Guardian.Plug.current_resource(conn)
    payslips = Payroll.list_my_payslips(user.id)

    render(conn, :index, payslips: payslips)
  end

  @doc """
  Retorna um contracheque específico do usuário autenticado.

  O token JWT deve ser enviado no header Authorization: Bearer <token>
  Retorna 404 se o contracheque não existir ou não pertencer ao usuário.
  """
  def show(conn, %{"id" => id}) do
    user = Guardian.Plug.current_resource(conn)
    payslip = Payroll.get_my_payslip!(id, user.id)

    render(conn, :show, payslip: payslip)
  end
end
