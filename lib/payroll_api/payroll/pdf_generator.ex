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
  - `employee: [:user, department: :company]`
  - `payslip_items: :rubric`
  """
  def generate(%Payslip{} = payslip) do
    payslip =
      Repo.preload(payslip,
        employee: [:user, department: :company],
        payslip_items: :rubric
      )

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
    department = employee.department
    company = if department, do: department.company, else: nil
    competence = format_competence(payslip.competence)

    """
    <!DOCTYPE html>
    <html lang="pt-BR">
    <head>
        <meta charset="UTF-8">
        <title>Holerite - #{competence}</title>
        <style>
          @page { size: A4; margin: 12mm 14mm; }

          * { margin: 0; padding: 0; box-sizing: border-box; }

          body {
            font-family: Helvetica, Arial, sans-serif;
            font-size: 11px;
            color: #1a1a2e;
            background: #ffffff;
          }

          /* ── Cabeçalho da empresa ───────────────────────── */
          .company-header {
            display: flex;
            justify-content: space-between;
            align-items: flex-end;
            border-bottom: 2px solid #1a1a2e;
            padding-bottom: 10px;
            margin-bottom: 12px;
          }
          .company-name {
            font-size: 16px;
            font-weight: bold;
            letter-spacing: 0.5px;
            color: #1a1a2e;
          }
          .company-meta {
            font-size: 10px;
            color: #5a5a72;
            margin-top: 3px;
          }
          .doc-title {
            text-align: right;
          }
          .doc-title h1 {
            font-size: 18px;
            font-weight: bold;
            color: #1a1a2e;
            letter-spacing: 1px;
            text-transform: uppercase;
          }
          .doc-title .period {
            font-size: 11px;
            color: #5a5a72;
            margin-top: 3px;
          }

          /* ── Grid de dados do funcionário ───────────────── */
          .employee-grid {
            display: grid;
            grid-template-columns: repeat(4, 1fr);
            gap: 6px 12px;
            background: #f4f6fb;
            border: 1px solid #dde3ef;
            border-radius: 4px;
            padding: 10px 14px;
            margin-bottom: 14px;
          }
          .eg-item label {
            display: block;
            font-size: 9px;
            font-weight: bold;
            text-transform: uppercase;
            color: #8890a4;
            margin-bottom: 2px;
            letter-spacing: 0.4px;
          }
          .eg-item .val {
            font-size: 11px;
            color: #1a1a2e;
            font-weight: 600;
          }

          /* ── Tabela de rubricas ──────────────────────────── */
          .rubrics-title {
            font-size: 11px;
            font-weight: bold;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            color: #1a1a2e;
            margin-bottom: 6px;
            border-left: 3px solid #1a1a2e;
            padding-left: 6px;
          }
          .rubrics-table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 14px;
          }
          .rubrics-table thead tr {
            background: #1a1a2e;
            color: #ffffff;
          }
          .rubrics-table th {
            padding: 7px 9px;
            font-size: 10px;
            font-weight: bold;
            text-transform: uppercase;
            letter-spacing: 0.4px;
          }
          .rubrics-table th.right,
          .rubrics-table td.right { text-align: right; }
          .rubrics-table td {
            padding: 6px 9px;
            border-bottom: 1px solid #eaedf5;
            font-size: 11px;
            color: #1a1a2e;
            vertical-align: top;
          }
          .rubrics-table tr:nth-child(even) td { background: #f8f9fd; }
          .rubrics-table td.earnings { color: #1a6b3c; font-family: monospace; }
          .rubrics-table td.deductions { color: #9b2226; font-family: monospace; }
          .rubrics-table td.empty { color: #bbb; }

          /* ── Bloco de totais ────────────────────────────── */
          .summary-row {
            display: flex;
            justify-content: flex-end;
            gap: 0;
            border-top: 2px solid #1a1a2e;
            margin-top: 4px;
          }
          .summary-cell {
            min-width: 160px;
            padding: 10px 14px;
            text-align: right;
            border-left: 1px solid #dde3ef;
          }
          .summary-cell label {
            display: block;
            font-size: 9px;
            font-weight: bold;
            text-transform: uppercase;
            letter-spacing: 0.4px;
            color: #8890a4;
            margin-bottom: 3px;
          }
          .summary-cell .val {
            font-size: 14px;
            font-weight: bold;
          }
          .summary-cell.earnings .val { color: #1a6b3c; }
          .summary-cell.deductions .val { color: #9b2226; }
          .summary-cell.net .val { color: #1a1a2e; font-size: 16px; }

          /* ── Bases / informativos ───────────────────────── */
          .footer-bases {
            margin-top: 18px;
            border-top: 1px solid #dde3ef;
            padding-top: 10px;
          }
          .footer-bases h3 {
            font-size: 10px;
            text-transform: uppercase;
            letter-spacing: 0.4px;
            color: #8890a4;
            margin-bottom: 6px;
          }
          .bases-table { width: 100%; border-collapse: collapse; font-size: 10px; }
          .bases-table th {
            text-align: left;
            padding: 5px 8px;
            background: #f4f6fb;
            border-bottom: 1px solid #dde3ef;
            font-weight: bold;
            text-transform: uppercase;
            letter-spacing: 0.3px;
            color: #5a5a72;
          }
          .bases-table td {
            padding: 5px 8px;
            border-bottom: 1px solid #f0f2f8;
            color: #1a1a2e;
          }
          .bases-table td.right { text-align: right; font-family: monospace; }

          /* ── Rodapé do documento ────────────────────────── */
          .doc-footer {
            margin-top: 24px;
            border-top: 1px solid #dde3ef;
            padding-top: 8px;
            font-size: 9px;
            color: #aab0c0;
            text-align: center;
          }

          /* ── Regras de paginação ────────────────────────── */
          .employee-grid { page-break-inside: avoid; break-inside: avoid; }
          .summary-row   { page-break-inside: avoid; break-inside: avoid; }
          .rubrics-table thead { display: table-header-group; }
          .rubrics-table tr { page-break-inside: avoid; break-inside: avoid; }
          .bases-table thead { display: table-header-group; }
          .bases-table tr { page-break-inside: avoid; break-inside: avoid; }

          @media print {
            body { background: #ffffff; }
            .container { margin: 0; padding: 0; box-shadow: none; }
          }
        </style>
    </head>
    <body>

      <!-- Cabeçalho da empresa -->
      <div class="company-header">
        <div>
          <div class="company-name">#{html_escape(company_name(company))}</div>
          <div class="company-meta">#{cnpj_label(company)}</div>
        </div>
        <div class="doc-title">
          <h1>Holerite</h1>
          <div class="period">Competência: #{competence}</div>
        </div>
      </div>

      <!-- Dados do funcionário -->
      <div class="employee-grid">
        <div class="eg-item">
          <label>Funcionário</label>
          <div class="val">#{html_escape(user.name)}</div>
        </div>
        <div class="eg-item">
          <label>Matrícula</label>
          <div class="val">#{html_escape(employee.registration)}</div>
        </div>
        <div class="eg-item">
          <label>CPF</label>
          <div class="val">#{format_cpf(user.cpf)}</div>
        </div>
        <div class="eg-item">
          <label>Data de Admissão</label>
          <div class="val">#{format_date_br(employee.admission_date)}</div>
        </div>
        <div class="eg-item">
          <label>Cargo</label>
          <div class="val">#{html_escape(employee.job_title)}</div>
        </div>
        <div class="eg-item">
          <label>Setor</label>
          <div class="val">#{html_escape(department_name_label(department))}</div>
        </div>
        <div class="eg-item">
          <label>Salário Base</label>
          <div class="val">#{format_money(payslip.base_salary)}</div>
        </div>
        <div class="eg-item">
          <label>Mês de Referência</label>
          <div class="val">#{competence}</div>
        </div>
      </div>

      <!-- Tabela unificada de rubricas -->
      <div class="rubrics-title">Lançamentos</div>
      <table class="rubrics-table">
        <thead>
          <tr>
            <th style="width:7%">Cód.</th>
            <th>Descrição</th>
            <th style="width:10%">Referência</th>
            <th class="right" style="width:14%">Proventos</th>
            <th class="right" style="width:14%">Descontos</th>
          </tr>
        </thead>
        <tbody>
          #{render_unified_rows(earnings, deductions)}
        </tbody>
      </table>

      <!-- Totais -->
      <div class="summary-row">
        <div class="summary-cell earnings">
          <label>Total Proventos</label>
          <div class="val">#{format_money(total_earnings)}</div>
        </div>
        <div class="summary-cell deductions">
          <label>Total Descontos</label>
          <div class="val">#{format_money(total_deductions)}</div>
        </div>
        <div class="summary-cell net">
          <label>Valor Líquido</label>
          <div class="val">#{format_money(net_amount)}</div>
        </div>
      </div>

      #{render_footer_bases(footer_items)}

      <div class="doc-footer">
        <p>Documento confidencial gerado automaticamente pelo sistema Payroll API.</p>
        <p>Emitido em: #{format_current_date()}</p>
      </div>

    </body>
    </html>
    """
  end

  # Gera as linhas da tabela unificada mesclando proventos e descontos.
  # Cada rubrica ocupa uma linha; a coluna correta (earnings/deductions) é preenchida.
  defp render_unified_rows(earnings, deductions) do
    earnings_rows =
      Enum.map(earnings, fn item ->
        """
        <tr>
          <td>#{html_escape(item.rubric.code)}</td>
          <td>#{html_escape(item.rubric.description)}</td>
          <td>#{html_escape(item.reference || "-")}</td>
          <td class="right earnings">#{format_money(item.amount)}</td>
          <td class="right empty">—</td>
        </tr>
        """
      end)

    deductions_rows =
      Enum.map(deductions, fn item ->
        """
        <tr>
          <td>#{html_escape(item.rubric.code)}</td>
          <td>#{html_escape(item.rubric.description)}</td>
          <td>#{html_escape(item.reference || "-")}</td>
          <td class="right empty">—</td>
          <td class="right deductions">#{format_money(item.amount)}</td>
        </tr>
        """
      end)

    (earnings_rows ++ deductions_rows) |> Enum.join()
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
          <td class="right">#{format_money(item.amount)}</td>
        </tr>
        """
      end)
      |> Enum.join()

    """
    <div class="footer-bases">
      <h3>Bases, Encargos e Itens Informativos</h3>
      <table class="bases-table">
        <thead>
          <tr>
            <th>Cód.</th>
            <th>Descrição</th>
            <th>Categoria</th>
            <th>Referência</th>
            <th class="right">Valor</th>
          </tr>
        </thead>
        <tbody>#{rows}</tbody>
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

  defp company_name(nil), do: "—"
  defp company_name(%{name: name}), do: name

  defp cnpj_label(nil), do: ""
  defp cnpj_label(%{cnpj: nil}), do: ""
  defp cnpj_label(%{cnpj: ""}), do: ""
  defp cnpj_label(%{cnpj: cnpj}), do: "CNPJ: #{format_cnpj(cnpj)}"

  defp format_cnpj(cnpj) when is_binary(cnpj) and byte_size(cnpj) == 14 do
    <<a::binary-size(2), b::binary-size(3), c::binary-size(3), d::binary-size(4),
      e::binary-size(2)>> = cnpj

    "#{a}.#{b}.#{c}/#{d}-#{e}"
  end

  defp format_cnpj(cnpj), do: cnpj

  defp department_name_label(nil), do: "—"
  defp department_name_label(%{name: name}), do: name

  defp format_date_br(nil), do: "—"
  defp format_date_br(%Date{} = date), do: Calendar.strftime(date, "%d/%m/%Y")
  defp format_date_br(_), do: "—"

  @months_pt %{
    1 => "Janeiro",
    2 => "Fevereiro",
    3 => "Março",
    4 => "Abril",
    5 => "Maio",
    6 => "Junho",
    7 => "Julho",
    8 => "Agosto",
    9 => "Setembro",
    10 => "Outubro",
    11 => "Novembro",
    12 => "Dezembro"
  }

  defp format_competence(%Date{month: month, year: year}) do
    "#{Map.fetch!(@months_pt, month)}/#{year}"
  end

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
    %Date{day: day, month: month, year: year} = Date.utc_today()
    month_name = Map.fetch!(@months_pt, month)
    "#{String.pad_leading(to_string(day), 2, "0")} de #{month_name} de #{year}"
  end
end
