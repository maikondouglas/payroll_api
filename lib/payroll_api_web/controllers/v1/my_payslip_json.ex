defmodule PayrollApiWeb.V1.MyPayslipJSON do
  alias Decimal
  import Ecto, only: [assoc_loaded?: 1]

  alias PayrollApi.Payroll.Payslip

  @doc """
  Renders a list of payslips.
  """
  def index(%{payslips: payslips}) do
    %{data: for(payslip <- payslips, do: data(payslip))}
  end

  @doc """
  Renders a single payslip with full details.
  """
  def show(%{payslip: payslip}) do
    %{data: data(payslip)}
  end

  defp data(%Payslip{} = payslip) do
    items = serialize_items(payslip)

    total_vencimentos =
      sum_by_category(items, "provento")

    total_descontos =
      sum_by_category(items, "desconto")

    valor_liquido = Decimal.sub(total_vencimentos, total_descontos)

    %{
      id: payslip.id,
      competence: payslip.competence,
      base_salary: decimal_to_string(payslip.base_salary),
      net_salary: decimal_to_string(payslip.net_salary),
      total_vencimentos: decimal_to_string(total_vencimentos),
      total_descontos: decimal_to_string(total_descontos),
      valor_liquido: decimal_to_string(valor_liquido),
      items: items,
      employee_id: payslip.employee_id,
      inserted_at: payslip.inserted_at,
      updated_at: payslip.updated_at
    }
  end

  defp serialize_items(%Payslip{payslip_items: payslip_items}) do
    if assoc_loaded?(payslip_items) do
      Enum.map(payslip_items, fn item ->
        rubric =
          if assoc_loaded?(item.rubric) do
            item.rubric
          else
            nil
          end

        %{
          code: rubric && rubric.code,
          description: rubric && rubric.description,
          category: rubric && rubric.category,
          reference: item.reference,
          amount: decimal_to_string(item.amount)
        }
      end)
    else
      []
    end
  end

  defp sum_by_category(items, category) do
    Enum.reduce(items, Decimal.new("0"), fn item, acc ->
      if item.category == category do
        Decimal.add(acc, parse_decimal(item.amount))
      else
        acc
      end
    end)
  end

  defp parse_decimal(value) when is_binary(value) do
    case Decimal.parse(value) do
      {decimal, _} -> decimal
      :error -> Decimal.new("0")
    end
  end

  defp parse_decimal(%Decimal{} = value), do: value
  defp parse_decimal(_), do: Decimal.new("0")

  defp decimal_to_string(%Decimal{} = value), do: Decimal.to_string(value, :normal)
  defp decimal_to_string(value) when is_binary(value), do: value
  defp decimal_to_string(_), do: "0"
end
