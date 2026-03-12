defmodule PayrollApi.Payroll.PayslipItem do
  @moduledoc """
  Schema de item de contracheque.

  Representa um lançamento financeiro de uma rubrica dentro de um
  contracheque específico.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias PayrollApi.Payroll.{Payslip, Rubric}

  schema "payslip_items" do
    field :reference, :string
    field :amount, :decimal

    belongs_to :payslip, Payslip
    belongs_to :rubric, Rubric

    timestamps(type: :utc_datetime)
  end

  @doc """
  Cria um changeset para inserção ou atualização de item de contracheque.
  """
  def changeset(payslip_item, attrs) do
    payslip_item
    |> cast(attrs, [:reference, :amount, :payslip_id, :rubric_id])
    |> validate_required([:amount, :payslip_id, :rubric_id])
    |> foreign_key_constraint(:payslip_id, message: "contracheque não existe")
    |> foreign_key_constraint(:rubric_id, message: "rubrica não existe")
  end
end
