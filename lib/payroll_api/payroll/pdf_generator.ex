defmodule PayrollApi.Payroll.PdfGenerator do
  @moduledoc """
  Módulo para geração de PDFs de contracheques.

  Cria PDFs dos contracheques (payslips) com informações do funcionário,
  salários e detalhes de rubricas.
  """

  require Logger

  @doc """
  Gera um PDF a partir de um contracheque.

  Retorna {:ok, pdf_binary} com o binário PDF pronto para download, ou {:error, reason} em caso de erro.
  O payslip deve ter o employee precarregado, o qual deve ter o user precarregado.

  ## Exemplos

      iex> payslip = Repo.get!(Payslip, 1) |> Repo.preload(employee: :user)
      iex> PayrollApi.Payroll.PdfGenerator.generate(payslip)
      {:ok, <<37, 80, 68, 70, ...>>}  # Binary PDF data starting with PDF magic bytes

  ## Returns

    - `{:ok, pdf_binary}` - O binário do PDF completamente formatado
    - `{:error, reason}` - Erro durante geração
  """
  def generate(payslip) do
    # Render HTML string with complete document structure
    html_string = render_html(payslip)

    # Validate HTML has required elements before sending to ChromicPDF
    cond do
      not String.contains?(html_string, "<!DOCTYPE html>") ->
        Logger.error("HTML gerado inválido para contracheque #{payslip.id}: falta <!DOCTYPE html>")
        {:error, "HTML structure is invalid - missing DOCTYPE"}

      not String.contains?(html_string, "</html>") ->
        Logger.error("HTML gerado inválido para contracheque #{payslip.id}: falta fechamento </html>")
        {:error, "HTML structure is invalid - missing closing HTML tag"}

      true ->
        # Convert HTML to PDF using ChromicPDF
        case ChromicPDF.print_to_pdf({:html, html_string}) do
          {:ok, pdf_binary} when is_binary(pdf_binary) and byte_size(pdf_binary) > 0 ->
            Logger.info(
              "PDF gerado com sucesso para contracheque #{payslip.id} (#{byte_size(pdf_binary)} bytes)"
            )
            {:ok, pdf_binary}

          {:ok, _pdf_binary} ->
            Logger.error("PDF gerado vazio para contracheque #{payslip.id}")
            {:error, "PDF binary is empty"}

          {:error, reason} ->
            Logger.error(
              "Erro ao gerar PDF do contracheque #{payslip.id}: #{inspect(reason)}"
            )
            {:error, reason}
        end
    end
  end

  # Renderiza o HTML do contracheque
  defp render_html(payslip) do
    employee = payslip.employee
    user = employee.user
    competence = format_competence(payslip.competence)
    base_salary = Decimal.to_string(payslip.base_salary)
    net_salary = Decimal.to_string(payslip.net_salary)

    rubricas_html = render_rubricas(payslip.details)

    """
    <!DOCTYPE html>
    <html lang="pt-BR">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Contracheque - #{competence}</title>
        <style>
            * {
                margin: 0;
                padding: 0;
                box-sizing: border-box;
            }

            body {
                font-family: Arial, sans-serif;
                background-color: #f5f5f5;
                padding: 20px;
            }

            .container {
                max-width: 900px;
                margin: 0 auto;
                background-color: white;
                padding: 40px;
                box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
            }

            .header {
                text-align: center;
                margin-bottom: 40px;
                border-bottom: 3px solid #2c3e50;
                padding-bottom: 20px;
            }

            .header h1 {
                font-size: 24px;
                color: #2c3e50;
                margin-bottom: 5px;
            }

            .header p {
                color: #7f8c8d;
                font-size: 14px;
            }

            .employee-info {
                display: grid;
                grid-template-columns: 1fr 1fr;
                gap: 20px;
                margin-bottom: 30px;
                padding: 20px;
                background-color: #ecf0f1;
                border-radius: 5px;
            }

            .info-item {
                display: flex;
                flex-direction: column;
            }

            .info-item label {
                font-weight: bold;
                color: #2c3e50;
                font-size: 12px;
                text-transform: uppercase;
                margin-bottom: 5px;
            }

            .info-item value {
                color: #34495e;
                font-size: 14px;
            }

            .salary-section {
                margin-bottom: 30px;
                border-top: 2px solid #bdc3c7;
                padding-top: 20px;
            }

            .salary-section h2 {
                font-size: 16px;
                color: #2c3e50;
                margin-bottom: 15px;
                font-weight: bold;
            }

            .salary-grid {
                display: grid;
                grid-template-columns: 1fr 1fr;
                gap: 20px;
            }

            .salary-item {
                padding: 15px;
                background-color: #f8f9fa;
                border-radius: 5px;
                border-left: 4px solid #3498db;
            }

            .salary-item label {
                display: block;
                font-size: 12px;
                color: #7f8c8d;
                text-transform: uppercase;
                margin-bottom: 5px;
                font-weight: bold;
            }

            .salary-item .value {
                font-size: 18px;
                color: #2c3e50;
                font-weight: bold;
            }

            .rubricas-section {
                margin-top: 30px;
                border-top: 2px solid #bdc3c7;
                padding-top: 20px;
            }

            .rubricas-section h2 {
                font-size: 16px;
                color: #2c3e50;
                margin-bottom: 15px;
                font-weight: bold;
            }

            .rubricas-table {
                width: 100%;
                border-collapse: collapse;
            }

            .rubricas-table thead {
                background-color: #34495e;
                color: white;
            }

            .rubricas-table th {
                padding: 12px;
                text-align: left;
                font-size: 12px;
                font-weight: bold;
                text-transform: uppercase;
            }

            .rubricas-table td {
                padding: 10px 12px;
                border-bottom: 1px solid #ecf0f1;
                font-size: 13px;
            }

            .rubricas-table tr:nth-child(even) {
                background-color: #f8f9fa;
            }

            .rubricas-table .value {
                text-align: right;
                font-family: monospace;
            }

            .footer {
                margin-top: 40px;
                text-align: center;
                color: #95a5a6;
                font-size: 11px;
                border-top: 1px solid #bdc3c7;
                padding-top: 20px;
            }
        </style>
    </head>
    <body>
        <div class="container">
            <!-- Header -->
            <div class="header">
                <h1>CONTRACHEQUE</h1>
                <p>Período: #{competence}</p>
            </div>

            <!-- Informações do Funcionário -->
            <div class="employee-info">
                <div class="info-item">
                    <label>Nome</label>
                    <value>#{user.name}</value>
                </div>
                <div class="info-item">
                    <label>CPF</label>
                    <value>#{format_cpf(user.cpf)}</value>
                </div>
                <div class="info-item">
                    <label>Matrícula</label>
                    <value>#{employee.registration}</value>
                </div>
                <div class="info-item">
                    <label>Função</label>
                    <value>#{employee.job_title}</value>
                </div>
            </div>

            <!-- Salários -->
            <div class="salary-section">
                <h2>Resumo de Salários</h2>
                <div class="salary-grid">
                    <div class="salary-item">
                        <label>Salário Base</label>
                        <div class="value">R$ #{format_currency(base_salary)}</div>
                    </div>
                    <div class="salary-item">
                        <label>Salário Líquido</label>
                        <div class="value">R$ #{format_currency(net_salary)}</div>
                    </div>
                </div>
            </div>

            <!-- Rubricas -->
            #{rubricas_html}

            <!-- Footer -->
            <div class="footer">
                <p>Este é um documento confidencial gerado automaticamente pelo sistema Payroll API.</p>
                <p>Data de Emissão: #{format_current_date()}</p>
            </div>
        </div>
    </body>
    </html>
    """
  end

  # Renderiza a tabela de rubricas
  defp render_rubricas(details) when is_map(details) and map_size(details) > 0 do
    rubricas_rows =
      details
      |> Enum.map(fn {rubrica, valor} ->
        """
        <tr>
            <td>#{rubrica}</td>
            <td class="value">#{format_rubrica_value(valor)}</td>
        </tr>
        """
      end)
      |> Enum.join()

    """
    <div class="rubricas-section">
        <h2>Detalhes de Rubricas</h2>
        <table class="rubricas-table">
            <thead>
                <tr>
                    <th>Rubrica</th>
                    <th style="text-align: right;">Valor</th>
                </tr>
            </thead>
            <tbody>
                #{rubricas_rows}
            </tbody>
        </table>
    </div>
    """
  end

  defp render_rubricas(_), do: ""

  # Formata a competência para exibição
  defp format_competence(competence) do
    case competence do
      %Date{} ->
        competence
        |> Calendar.strftime("%B de %Y")
        |> String.replace("January", "Janeiro")
        |> String.replace("February", "Fevereiro")
        |> String.replace("March", "Março")
        |> String.replace("April", "Abril")
        |> String.replace("May", "Maio")
        |> String.replace("June", "Junho")
        |> String.replace("July", "Julho")
        |> String.replace("August", "Agosto")
        |> String.replace("September", "Setembro")
        |> String.replace("October", "Outubro")
        |> String.replace("November", "Novembro")
        |> String.replace("December", "Dezembro")

      _ ->
        "N/A"
    end
  end

  # Formata CPF com máscara
  defp format_cpf(cpf) when is_binary(cpf) and byte_size(cpf) == 11 do
    <<a::binary-size(3), b::binary-size(3), c::binary-size(3), d::binary-size(2)>> = cpf
    "#{a}.#{b}.#{c}-#{d}"
  end

  defp format_cpf(cpf), do: cpf

  # Formata valor para moeda
  defp format_currency(value) when is_binary(value) do
    value
    |> String.split(".")
    |> case do
      [integer] -> "#{integer},00"
      [integer, decimal] -> "#{integer},#{String.pad_trailing(decimal, 2, "0")}"
      _ -> "0,00"
    end
  end

  defp format_currency(_), do: "0,00"

  # Formata valor de rubrica
  defp format_rubrica_value(value) when is_binary(value) do
    "R$ #{format_currency(value)}"
  end

  defp format_rubrica_value(_), do: "R$ 0,00"

  # Formata a data atual
  defp format_current_date do
    Date.utc_today()
    |> Calendar.strftime("%d de %B de %Y")
    |> String.replace("January", "Janeiro")
    |> String.replace("February", "Fevereiro")
    |> String.replace("March", "Março")
    |> String.replace("April", "Abril")
    |> String.replace("May", "Maio")
    |> String.replace("June", "Junho")
    |> String.replace("July", "Julho")
    |> String.replace("August", "Agosto")
    |> String.replace("September", "Setembro")
    |> String.replace("October", "Outubro")
    |> String.replace("November", "Novembro")
    |> String.replace("December", "Dezembro")
  end
end
