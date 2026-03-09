defmodule PayrollApiWeb.V1.MyPayslipJSON do
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
    %{
      id: payslip.id,
      competence: payslip.competence,
      base_salary: payslip.base_salary,
      net_salary: payslip.net_salary,
      details: payslip.details,
      employee_id: payslip.employee_id,
      inserted_at: payslip.inserted_at,
      updated_at: payslip.updated_at
    }
  end
end
