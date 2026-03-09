defmodule PayrollApiWeb.V1.MyPayslipController do
  use PayrollApiWeb, :controller

  alias PayrollApi.Payroll
  alias PayrollApi.Auth.Guardian

  action_fallback PayrollApiWeb.FallbackController

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
