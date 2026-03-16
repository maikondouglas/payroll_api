defmodule PayrollApi.HR do
  @moduledoc """
  The HR context.
  """

  import Ecto.Query, warn: false
  alias PayrollApi.Repo

  alias PayrollApi.HR.Employee

  @doc """
  Returns the list of employees.

  ## Examples

      iex> list_employees()
      [%Employee{}, ...]

  """
  def list_employees do
    Repo.all(from e in Employee, preload: [department: [:company]])
  end

  @doc """
  Gets a single employee.

  Raises `Ecto.NoResultsError` if the Employee does not exist.

  ## Examples

      iex> get_employee!(123)
      %Employee{}

      iex> get_employee!(456)
      ** (Ecto.NoResultsError)

  """
  def get_employee!(id), do: Repo.get!(Employee, id) |> Repo.preload(department: [:company])

  @doc """
  Gets a single employee by registration.

  Returns nil if the Employee does not exist.
  """
  def get_employee_by_registration(registration),
    do: Repo.get_by(Employee, registration: registration) |> maybe_preload_employee_department()

  @doc """
  Creates a employee.

  ## Examples

      iex> create_employee(%{field: value})
      {:ok, %Employee{}}

      iex> create_employee(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_employee(attrs \\ %{}) do
    %Employee{}
    |> Employee.changeset(attrs)
    |> Repo.insert()
    |> maybe_preload_employee_department()
  end

  @doc """
  Updates a employee.

  ## Examples

      iex> update_employee(employee, %{field: new_value})
      {:ok, %Employee{}}

      iex> update_employee(employee, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_employee(%Employee{} = employee, attrs) do
    employee
    |> Employee.changeset(attrs)
    |> Repo.update()
    |> maybe_preload_employee_department()
  end

  @doc """
  Deletes a employee.

  ## Examples

      iex> delete_employee(employee)
      {:ok, %Employee{}}

      iex> delete_employee(employee)
      {:error, %Ecto.Changeset{}}

  """
  def delete_employee(%Employee{} = employee) do
    Repo.delete(employee)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking employee changes.

  ## Examples

      iex> change_employee(employee)
      %Ecto.Changeset{data: %Employee{}}

  """
  def change_employee(%Employee{} = employee, attrs \\ %{}) do
    Employee.changeset(employee, attrs)
  end

  defp maybe_preload_employee_department({:ok, %Employee{} = employee}) do
    {:ok, Repo.preload(employee, department: [:company])}
  end

  defp maybe_preload_employee_department(%Employee{} = employee) do
    Repo.preload(employee, department: [:company])
  end

  defp maybe_preload_employee_department(result), do: result
end
