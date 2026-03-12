defmodule PayrollApi.Payroll.PdfGenerator do
  @moduledoc """
  Módulo para geração de PDFs de contracheques.

  Gera PDFs a partir da estrutura relacional:
  payslip -> payslip_items -> rubric.
  """

  alias PayrollApi.Payroll.Payslip
  alias PayrollApi.Repo

  require Logger

  @doc """
  Gera um PDF a partir de um contracheque.

  Retorna `{:ok, pdf_binary}` com o binário PDF pronto para download,
  ou `{:error, reason}` em caso de erro.

  O próprio generator garante os preloads necessários:
  - `employee: :user`
  - `payslip_items: :rubric`
  """
  def generate(%Payslip{} = payslip) do
    payslip = Repo.preload(payslip, [employee: :user, payslip_items: :rubric])

    {earnings, deductions, footer_items} = split_items_by_category(payslip.payslip_items)

    total_earnings = sum_items(earnings)
    total_deductions = sum_items(deductions)

    net_amount =
      payslip.base_salary
      |> Decimal.add(total_earnings)
      |> Decimal.sub(total_deductions)

    html_string =
      render_html(
        payslip,
        earnings,
        deductions,
        footer_items,
        total_earnings,
        total_deductions,
        net_amount
      )

    cond do
      not String.contains?(html_string, "<!DOCTYPE html>") ->
        Logger.error("Invalid HTML generated for payslip #{payslip.id}: missing <!DOCTYPE html>")
        {:error, "HTML structure is invalid - missing DOCTYPE"}

      not String.contains?(html_string, "</html>") ->
        Logger.error("Invalid HTML generated for payslip #{payslip.id}: missing closing </html>")
        {:error, "HTML structure is invalid - missing closing HTML tag"}

      true ->
        case ChromicPDF.print_to_pdf({:html, html_string}) do
          {:ok, pdf_binary} when is_binary(pdf_binary) and byte_size(pdf_binary) > 0 ->
            Logger.info(
              "PDF generated successfully for payslip #{payslip.id} (#{byte_size(pdf_binary)} bytes)"
            )

            {:ok, pdf_binary}

          {:ok, _pdf_binary} ->
            Logger.error("Empty PDF generated for payslip #{payslip.id}")
            {:error, "PDF binary is empty"}

          {:error, reason} ->
            Logger.error("Failed to generate PDF for payslip #{payslip.id}: #{inspect(reason)}")
            {:error, reason}
        end
    end
  end

  defp render_html(
         payslip,
         earnings,
         deductions,
         footer_items,
         total_earnings,
         total_deductions,
         net_amount
       ) do
    employee = payslip.employee
    user = employee.user
    competence = format_competence(payslip.competence)

    """
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Payslip - #{competence}</title>
        <style>
          @page {
            size: A4;
            margin: 14mm 12mm;
          }

            * { margin: 0; padding: 0; box-sizing: border-box; }
            body { font-family: Arial, sans-serif; background-color: #f5f5f5; padding: 20px; }
            .container { max-width: 920px; margin: 0 auto; background-color: white; padding: 36px; box-shadow: 0 2px 8px rgba(0,0,0,0.1); }
            .header { text-align: center; margin-bottom: 30px; border-bottom: 3px solid #2c3e50; padding-bottom: 16px; }
            .header h1 { font-size: 24px; color: #2c3e50; margin-bottom: 5px; }
            .header p { color: #7f8c8d; font-size: 14px; }
            .employee-info { display: grid; grid-template-columns: 1fr 1fr; gap: 16px; margin-bottom: 22px; padding: 16px; background-color: #ecf0f1; border-radius: 5px; }
            .info-item label { display: block; font-weight: bold; color: #2c3e50; font-size: 12px; text-transform: uppercase; margin-bottom: 4px; }
            .info-item .value { color: #34495e; font-size: 14px; }
            .salary-section { margin-bottom: 24px; border-top: 2px solid #bdc3c7; padding-top: 16px; }
            .salary-section h2 { font-size: 16px; color: #2c3e50; margin-bottom: 12px; font-weight: bold; }
            .salary-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; }
            .salary-item { padding: 12px; background-color: #f8f9fa; border-radius: 5px; border-left: 4px solid #3498db; }
            .salary-item label { display: block; font-size: 12px; color: #7f8c8d; text-transform: uppercase; margin-bottom: 4px; font-weight: bold; }
            .salary-item .value { font-size: 17px; color: #2c3e50; font-weight: bold; }
            .rubrics-section { margin-top: 22px; border-top: 2px solid #bdc3c7; padding-top: 16px; break-inside: auto; page-break-inside: auto; }
            .rubrics-section h2 { font-size: 16px; color: #2c3e50; margin-bottom: 12px; font-weight: bold; }
            .rubrics-table { width: 100%; border-collapse: collapse; }
            .rubrics-table thead { background-color: #34495e; color: white; }
            .rubrics-table th { padding: 10px; text-align: left; font-size: 12px; font-weight: bold; text-transform: uppercase; }
            .rubrics-table td { padding: 9px 10px; border-bottom: 1px solid #ecf0f1; font-size: 12px; }
            .rubrics-table tr:nth-child(even) { background-color: #f8f9fa; }
            .rubrics-table .value { text-align: right; font-family: monospace; }
            .summary-box { margin-top: 20px; display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 10px; break-inside: auto; page-break-inside: auto; }
            .summary-item { border: 1px solid #d6dde3; border-radius: 5px; padding: 10px; background-color: #fbfcfd; }
            .summary-item label { display: block; text-transform: uppercase; color: #6b7c8f; font-size: 11px; margin-bottom: 5px; font-weight: bold; }
            .summary-item .value { font-size: 15px; color: #2c3e50; font-weight: bold; }
            .footer-bases { margin-top: 24px; border-top: 2px solid #bdc3c7; padding-top: 14px; break-before: auto; page-break-before: auto; }
            .footer-bases h3 { font-size: 14px; color: #2c3e50; margin-bottom: 10px; }
            .bases-table { width: 100%; border-collapse: collapse; font-size: 12px; }
            .bases-table th { text-align: left; padding: 8px; background: #eef2f6; border-bottom: 1px solid #d6dde3; }
            .bases-table td { padding: 8px; border-bottom: 1px solid #eef2f6; }
            .bases-table .value { text-align: right; font-family: monospace; }
            .footer { margin-top: 30px; text-align: center; color: #95a5a6; font-size: 11px; border-top: 1px solid #bdc3c7; padding-top: 14px; }

            /* Regras para impressão/PDF com quebra otimizada em A4 */
            .employee-info,
            .salary-section {
              break-inside: avoid-page;
              page-break-inside: avoid;
            }

            .summary-item {
              break-inside: avoid-page;
              page-break-inside: avoid;
            }

            .rubrics-section h2,
            .footer-bases h3 {
              break-after: avoid-page;
              page-break-after: avoid;
            }

            .rubrics-table,
            .bases-table {
              page-break-inside: auto;
            }

            .rubrics-table thead,
            .bases-table thead {
              display: table-header-group;
            }

            .rubrics-table tr,
            .bases-table tr {
              break-inside: avoid;
              page-break-inside: avoid;
            }

            .rubrics-table tfoot,
            .bases-table tfoot {
              display: table-footer-group;
            }

            @media print {
              body {
                background: #ffffff;
                padding: 0;
                -webkit-print-color-adjust: exact;
                print-color-adjust: exact;
              }

              .container {
                max-width: none;
                margin: 0;
                padding: 0;
                box-shadow: none;
              }
            }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>PAYSLIP</h1>
                <p>Period: #{competence}</p>
            </div>

            <div class="employee-info">
                <div class="info-item">
                    <label>Name</label>
                    <div class="value">#{html_escape(user.name)}</div>
                </div>
                <div class="info-item">
                    <label>CPF</label>
                    <div class="value">#{format_cpf(user.cpf)}</div>
                </div>
                <div class="info-item">
                    <label>Registration</label>
                    <div class="value">#{html_escape(employee.registration)}</div>
                </div>
                <div class="info-item">
                    <label>Job Title</label>
                    <div class="value">#{html_escape(employee.job_title)}</div>
                </div>
            </div>

            <div class="salary-section">
                  <h2>Salary Summary</h2>
                <div class="salary-grid">
                    <div class="salary-item">
                      <label>Base Salary</label>
                        <div class="value">#{format_money(payslip.base_salary)}</div>
                    </div>
                    <div class="salary-item">
                      <label>Stored Net Salary</label>
                        <div class="value">#{format_money(payslip.net_salary)}</div>
                    </div>
                </div>
            </div>

                #{render_financial_section("Earnings", earnings)}
                #{render_financial_section("Deductions", deductions)}

            <div class="summary-box">
                <div class="summary-item">
                    <label>Total Earnings</label>
                    <div class="value">#{format_money(total_earnings)}</div>
                </div>
                <div class="summary-item">
                    <label>Total Deductions</label>
                    <div class="value">#{format_money(total_deductions)}</div>
                </div>
                <div class="summary-item">
                    <label>Net Amount</label>
                    <div class="value">#{format_money(net_amount)}</div>
                </div>
            </div>

                #{render_footer_bases(footer_items)}

            <div class="footer">
                <p>This is a confidential document generated automatically by the Payroll API system.</p>
                  <p>Issued on: #{format_current_date()}</p>
            </div>
        </div>
    </body>
    </html>
    """
  end

  defp render_financial_section(_title, []), do: ""

  defp render_financial_section(title, items) do
    rows =
      items
      |> Enum.map(&render_item_row/1)
      |> Enum.join()

    """
    <div class="rubrics-section">
        <h2>#{title}</h2>
      <table class="rubrics-table">
            <thead>
                <tr>
            <th>Code</th>
            <th>Description</th>
            <th>Reference</th>
            <th style="text-align: right;">Amount</th>
                </tr>
            </thead>
            <tbody>
                #{rows}
            </tbody>
        </table>
    </div>
    """
  end

  defp render_item_row(item) do
    rubric = item.rubric
    reference = item.reference || "-"

    """
    <tr>
        <td>#{html_escape(rubric.code)}</td>
        <td>#{html_escape(rubric.description)}</td>
        <td>#{html_escape(reference)}</td>
        <td class="value">#{format_money(item.amount)}</td>
    </tr>
    """
  end

  defp render_footer_bases([]), do: ""

  defp render_footer_bases(items) do
    rows =
      items
      |> Enum.map(fn item ->
        """
        <tr>
            <td>#{html_escape(item.rubric.code)}</td>
            <td>#{html_escape(item.rubric.description)}</td>
            <td>#{html_escape(item.rubric.category)}</td>
            <td>#{html_escape(item.reference || "-")}</td>
            <td class="value">#{format_money(item.amount)}</td>
        </tr>
        """
      end)
      |> Enum.join()

    """
    <div class="footer-bases">
      <h3>Base, Charge, and Informational Items</h3>
      <table class="bases-table">
        <thead>
          <tr>
            <th>Code</th>
            <th>Description</th>
            <th>Category</th>
            <th>Reference</th>
            <th style="text-align: right;">Amount</th>
          </tr>
        </thead>
        <tbody>
          #{rows}
        </tbody>
      </table>
    </div>
    """
  end

  defp split_items_by_category(items) do
    items
    |> Enum.filter(&valid_rubric_item?/1)
    |> Enum.reduce({[], [], []}, fn item, {proventos, descontos, bases_rodape} ->
      case item.rubric.category do
        "provento" -> {[item | proventos], descontos, bases_rodape}
        "desconto" -> {proventos, [item | descontos], bases_rodape}
        "base" -> {proventos, descontos, [item | bases_rodape]}
        "encargo" -> {proventos, descontos, [item | bases_rodape]}
        "informativa" -> {proventos, descontos, [item | bases_rodape]}
        _ -> {proventos, descontos, bases_rodape}
      end
    end)
    |> then(fn {p, d, b} -> {Enum.reverse(p), Enum.reverse(d), Enum.reverse(b)} end)
  end

  defp valid_rubric_item?(item) do
    item.rubric && is_binary(item.rubric.code) && is_binary(item.rubric.category)
  end

  defp sum_items(items) do
    Enum.reduce(items, Decimal.new("0"), fn item, acc ->
      Decimal.add(acc, item.amount || Decimal.new("0"))
    end)
  end

  defp format_competence(%Date{} = competence), do: Calendar.strftime(competence, "%B %Y")

  defp format_competence(_), do: "N/A"

  defp format_cpf(cpf) when is_binary(cpf) and byte_size(cpf) == 11 do
    <<a::binary-size(3), b::binary-size(3), c::binary-size(3), d::binary-size(2)>> = cpf
    "#{a}.#{b}.#{c}-#{d}"
  end

  defp format_cpf(cpf), do: cpf

  # Formata decimal para moeda brasileira: R$ 1.234,56
  defp format_money(%Decimal{} = value) do
    value
    |> Decimal.round(2)
    |> Decimal.to_string(:normal)
    |> format_number_pt_br()
    |> then(&"R$ #{&1}")
  end

  defp format_money(value) when is_binary(value) do
    case Decimal.parse(value) do
      {decimal, _} -> format_money(decimal)
      :error -> "R$ 0,00"
    end
  end

  defp format_money(_), do: "R$ 0,00"

  defp format_number_pt_br(number_string) do
    [int_part, dec_part] =
      number_string
      |> String.split(".")
      |> case do
        [int] -> [int, "00"]
        [int, dec] -> [int, String.pad_trailing(dec, 2, "0") |> String.slice(0, 2)]
      end

    formatted_int =
      int_part
      |> String.reverse()
      |> String.replace(~r/(\d{3})(?=\d)/, "\\1.")
      |> String.reverse()

    "#{formatted_int},#{dec_part}"
  end

  defp html_escape(nil), do: ""

  defp html_escape(value) do
    value
    |> to_string()
    |> Phoenix.HTML.html_escape()
    |> Phoenix.HTML.safe_to_string()
  end

  defp format_current_date do
    Date.utc_today()
    |> Calendar.strftime("%d %B %Y")
  end
end
