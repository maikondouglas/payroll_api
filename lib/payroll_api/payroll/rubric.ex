defmodule PayrollApi.Payroll.Rubric do
  @moduledoc """
  Schema de catálogo de rubricas.

  Representa o dicionário mestre de rubricas da folha de pagamento,
  separado dos lançamentos financeiros mensais.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias PayrollApi.Payroll.PayslipItem

  @categories ["provento", "desconto", "base", "encargo", "informativa"]

  schema "rubrics" do
    field :code, :string
    field :description, :string
    field :category, :string

    has_many :payslip_items, PayslipItem, foreign_key: :rubric_id

    timestamps(type: :utc_datetime)
  end

  @doc """
  Cria um changeset para inserção ou atualização de rubrica.
  """
  def changeset(rubric, attrs) do
    rubric
    |> cast(attrs, [:code, :description, :category])
    |> validate_required([:code, :description, :category])
    |> validate_inclusion(:category, @categories)
    |> unique_constraint(:code)
  end
end
