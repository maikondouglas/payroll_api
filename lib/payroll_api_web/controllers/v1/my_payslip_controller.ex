defmodule PayrollApiWeb.V1.MyPayslipController do
  use PayrollApiWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias PayrollApi.Payroll
  alias PayrollApi.Auth.Guardian

  alias PayrollApiWeb.Schemas.{PayslipList, Payslip, ErrorResponse}

  action_fallback PayrollApiWeb.FallbackController

  tags(["Contracheques"])

  operation(:index,
    summary: "Listar contracheques do usuário",
    description:
      "Retorna todos os contracheques do usuário autenticado, ordenados por competência (mais recente primeiro)",
    security: [%{"bearer" => []}],
    responses: [
      ok: {"Lista de contracheques", "application/json", PayslipList},
      unauthorized: {"Token ausente ou inválido", "application/json", ErrorResponse}
    ]
  )

  operation(:show,
    summary: "Obter contracheque específico",
    description:
      "Retorna um contracheque específico do usuário autenticado, incluindo detalhes de rubricas",
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
  )

  operation(:download,
    summary: "Descarregar contracheque em PDF",
    description: "Gera e baixa o contracheque do usuário autenticado em formato PDF",
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
      ok: {"Arquivo PDF do contracheque", "application/pdf", nil},
      not_found: {"Contracheque não encontrado", "application/json", ErrorResponse},
      unauthorized: {"Token ausente ou inválido", "application/json", ErrorResponse},
      internal_server_error: {"Erro ao gerar PDF", "application/json", ErrorResponse}
    ]
  )

  @doc """
  Retorna a lista de contracheques do usuário autenticado.

  O token JWT deve ser enviado no header Authorization: Bearer <token>
  Retorna os contracheques ordenados por competência decrescente.
  """
  def index(conn, _params) do
    user = Guardian.Plug.current_resource(conn)
    payslips = Payroll.list_my_payslips(user.id)

    conn
    |> put_status(:ok)
    |> render(:index, payslips: payslips)
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

  @doc """
  Descarrega um contracheque específico em formato PDF.

  O token JWT deve ser enviado no header Authorization: Bearer <token>
  Retorna 404 se o contracheque não existir ou não pertencer ao usuário.
  Retorna 500 se houver erro na geração do PDF.
  """
def download(conn, %{"id" => id}) do
    user = Guardian.Plug.current_resource(conn)

    # O PdfGenerator garante os preloads necessários internamente.
    payslip = Payroll.get_my_payslip!(id, user.id)

    case PayrollApi.Payroll.PdfGenerator.generate(payslip) do
      {:ok, base64_pdf} when is_binary(base64_pdf) ->

        # A MÁGICA AQUI: Decodifica de texto Base64 para arquivo binário PDF
        real_pdf_bytes = Base.decode64!(base64_pdf)

        competence = format_competence(payslip.competence)
        filename = "contracheque_#{String.replace(competence, ~r/[^a-zA-Z0-9_]/, "_")}.pdf"

        conn
        |> put_resp_content_type("application/pdf")
        # Envia os bytes reais, e não o texto em Base64
        |> send_download({:binary, real_pdf_bytes}, filename: filename)

      {:ok, _} ->
        render_error(conn, 500, "PDF gerado inválido")

      {:error, reason} ->
        render_error(conn, 500, "Erro ao gerar PDF do contracheque: #{inspect(reason)}")
    end
  end

  defp render_error(conn, status, message) do
    conn
    |> put_status(status)
    |> put_resp_content_type("application/json")
    |> send_resp(status, Jason.encode!(%{"error" => message}))
  end

  defp format_competence(competence) do
    case competence do
      %Date{month: month, year: year} ->
        month_name = get_month_name(month)
        "#{month_name}_#{year}"

      _ ->
        "contracheque"
    end
  end

  defp get_month_name(month) do
    case month do
      1 -> "janeiro"
      2 -> "fevereiro"
      3 -> "marco"
      4 -> "abril"
      5 -> "maio"
      6 -> "junho"
      7 -> "julho"
      8 -> "agosto"
      9 -> "setembro"
      10 -> "outubro"
      11 -> "novembro"
      12 -> "dezembro"
      _ -> "mes_#{month}"
    end
  end
end
