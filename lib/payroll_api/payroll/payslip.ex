defmodule PayrollApi.Payroll.Payslip do
  @moduledoc """
  Schema de Contracheque (Payslip).
  
  Representa a folha de pagamento de um funcionário em um período específico.
  Armazena salário base, salário líquido e detalhes de rubricas extras em JSON.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias PayrollApi.HR.Employee

  schema "payslips" do
    field :competence, :date
    field :base_salary, :decimal
    field :net_salary, :decimal
    field :details, :map, default: %{}

    belongs_to :employee, Employee

    timestamps(type: :utc_datetime)
  end

  @doc """
  Cria um changeset para inserção ou atualização de contracheque.
  """
  def changeset(payslip, attrs) do
    payslip
    |> cast(attrs, [:competence, :base_salary, :net_salary, :details, :employee_id])
    |> validate_required([:competence, :base_salary, :net_salary, :employee_id])
    |> validate_number(:base_salary, greater_than: 0, message: "deve ser maior que 0")
    |> validate_number(:net_salary, greater_than_or_equal_to: 0, message: "não pode ser negativo")
    |> validate_net_salary_less_than_base()
    |> unique_constraint([:employee_id, :competence], 
        message: "já existe contracheque para este funcionário neste período")
    |> foreign_key_constraint(:employee_id, message: "funcionário não existe")
  end

  # Validação customizada: salário líquido não pode ser maior que o salário base
  defp validate_net_salary_less_than_base(changeset) do
    case {get_change(changeset, :base_salary), get_change(changeset, :net_salary)} do
      {base, net} when is_number(base) and is_number(net) and net > base ->
        add_error(changeset, :net_salary, "não pode ser maior que salário base")

      _ ->
        changeset
    end
  end
end
