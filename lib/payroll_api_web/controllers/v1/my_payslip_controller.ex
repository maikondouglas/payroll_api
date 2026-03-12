defmodule PayrollApiWeb.V1.MyPayslipController do
  use PayrollApiWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias PayrollApi.Payroll
  alias PayrollApi.Auth.Guardian

  alias PayrollApiWeb.Schemas.{PayslipList, Payslip, ErrorResponse}

  action_fallback PayrollApiWeb.FallbackController

  tags(["Payslips"])

  operation(:index,
    summary: "List authenticated user payslips",
    description:
      "Returns all payslips for the authenticated user, ordered by competence descending.",
    security: [%{"bearer" => []}],
    responses: [
      ok: {"Payslip list", "application/json", PayslipList},
      unauthorized: {"Missing or invalid token", "application/json", ErrorResponse}
    ]
  )

  operation(:show,
    summary: "Get specific payslip",
    description:
      "Returns a specific payslip for the authenticated user, including rubric item details.",
    security: [%{"bearer" => []}],
    parameters: [
      id: [
        in: :path,
        description: "Payslip ID",
        schema: %OpenApiSpex.Schema{type: :integer},
        required: true
      ]
    ],
    responses: [
      ok: {"Payslip found", "application/json", Payslip},
      not_found: {"Payslip not found", "application/json", ErrorResponse},
      unauthorized: {"Missing or invalid token", "application/json", ErrorResponse}
    ]
  )

  operation(:download,
    summary: "Download payslip as PDF",
    description: "Generates and downloads the authenticated user's payslip as a PDF file.",
    security: [%{"bearer" => []}],
    parameters: [
      id: [
        in: :path,
        description: "Payslip ID",
        schema: %OpenApiSpex.Schema{type: :integer},
        required: true
      ]
    ],
    responses: [
      ok: {"Payslip PDF file", "application/pdf", nil},
      not_found: {"Payslip not found", "application/json", ErrorResponse},
      unauthorized: {"Missing or invalid token", "application/json", ErrorResponse},
      internal_server_error: {"Failed to generate PDF", "application/json", ErrorResponse}
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
        filename = "payslip_#{String.replace(competence, ~r/[^a-zA-Z0-9_]/, "_")}.pdf"

        conn
        |> put_resp_content_type("application/pdf")
        # Envia os bytes reais, e não o texto em Base64
        |> send_download({:binary, real_pdf_bytes}, filename: filename)

      {:ok, _} ->
        render_error(conn, 500, "Generated PDF is invalid")

      {:error, reason} ->
        render_error(conn, 500, "Failed to generate payslip PDF: #{inspect(reason)}")
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
        "payslip"
    end
  end

  defp get_month_name(month) do
    case month do
      1 -> "january"
      2 -> "february"
      3 -> "march"
      4 -> "april"
      5 -> "may"
      6 -> "june"
      7 -> "july"
      8 -> "august"
      9 -> "september"
      10 -> "october"
      11 -> "november"
      12 -> "december"
      _ -> "month_#{month}"
    end
  end
end
