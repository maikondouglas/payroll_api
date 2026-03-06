defmodule PayrollApi.Payroll do
  @moduledoc """
  The Payroll context.
  """

  import Ecto.Query, warn: false
  alias PayrollApi.Repo

  alias PayrollApi.Payroll.Payslip

  @doc """
  Returns the list of payslips.

  ## Examples

      iex> list_payslips()
      [%Payslip{}, ...]

  """
  def list_payslips do
    Repo.all(Payslip)
  end

  @doc """
  Gets a single payslip.

  Raises `Ecto.NoResultsError` if the Payslip does not exist.

  ## Examples

      iex> get_payslip!(123)
      %Payslip{}

      iex> get_payslip!(456)
      ** (Ecto.NoResultsError)

  """
  def get_payslip!(id), do: Repo.get!(Payslip, id)

  @doc """
  Gets payslips by employee.

  ## Examples

      iex> list_payslips_by_employee(123)
      [%Payslip{}, ...]

  """
  def list_payslips_by_employee(employee_id) do
    Repo.all(from p in Payslip, where: p.employee_id == ^employee_id, order_by: [desc: p.competence])
  end

  @doc """
  Gets a payslip by employee_id and competence.

  Returns nil if the Payslip does not exist.
  """
  def get_payslip_by_employee_and_competence(employee_id, competence) do
    Repo.get_by(Payslip, employee_id: employee_id, competence: competence)
  end

  @doc """
  Creates a payslip.

  ## Examples

      iex> create_payslip(%{field: value})
      {:ok, %Payslip{}}

      iex> create_payslip(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_payslip(attrs \\ %{}) do
    %Payslip{}
    |> Payslip.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a payslip.

  ## Examples

      iex> update_payslip(payslip, %{field: new_value})
      {:ok, %Payslip{}}

      iex> update_payslip(payslip, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_payslip(%Payslip{} = payslip, attrs) do
    payslip
    |> Payslip.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a payslip.

  ## Examples

      iex> delete_payslip(payslip)
      {:ok, %Payslip{}}

      iex> delete_payslip(payslip)
      {:error, %Ecto.Changeset{}}

  """
  def delete_payslip(%Payslip{} = payslip) do
    Repo.delete(payslip)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking payslip changes.

  ## Examples

      iex> change_payslip(payslip)
      %Ecto.Changeset{data: %Payslip{}}

  """
  def change_payslip(%Payslip{} = payslip, attrs \\ %{}) do
    Payslip.changeset(payslip, attrs)
  end
end
