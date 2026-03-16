defmodule PayrollApi.Organizations do
  @moduledoc """
  The Organizations context.
  """

  import Ecto.Query, warn: false

  alias PayrollApi.Organizations.{Company, Department}
  alias PayrollApi.Repo

  def list_companies do
    Repo.all(Company)
  end

  def get_company!(id), do: Repo.get!(Company, id)

  def get_company_by_name(name) when is_binary(name) do
    Repo.get_by(Company, name: String.trim(name))
  end

  def create_company(attrs \\ %{}) do
    %Company{}
    |> Company.changeset(attrs)
    |> Repo.insert()
  end

  def list_departments do
    Repo.all(from d in Department, preload: [:company])
  end

  def get_department!(id), do: Repo.get!(Department, id) |> Repo.preload(:company)

  def get_department_by_company_and_name(company_id, name)
      when is_integer(company_id) and is_binary(name) do
    Repo.get_by(Department, company_id: company_id, name: String.trim(name))
  end

  def create_department(attrs \\ %{}) do
    %Department{}
    |> Department.changeset(attrs)
    |> Repo.insert()
    |> maybe_preload_department_company()
  end

  def update_department(%Department{} = department, attrs) do
    department
    |> Department.changeset(attrs)
    |> Repo.update()
    |> maybe_preload_department_company()
  end

  def find_or_create_department(company_name, department_name, company_attrs \\ %{})
      when is_binary(company_name) and is_binary(department_name) do
    normalized_company_name = String.trim(company_name)
    normalized_department_name = String.trim(department_name)

    with {:ok, company} <- find_or_create_company(normalized_company_name, company_attrs),
         {:ok, department} <-
           find_or_create_department_for_company(company, normalized_department_name) do
      {:ok, department}
    end
  end

  defp find_or_create_company(name, attrs) do
    case Repo.get_by(Company, name: name) do
      %Company{} = company ->
        {:ok, company}

      nil ->
        attrs
        |> Map.put(:name, name)
        |> Map.put_new(:is_active, true)
        |> create_company_with_retry()
    end
  end

  defp create_company_with_retry(attrs) do
    case create_company(attrs) do
      {:ok, company} ->
        {:ok, company}

      {:error, %Ecto.Changeset{errors: [name: {_, [constraint: :unique, constraint_name: _]}]}} ->
        {:ok, Repo.get_by!(Company, name: Map.fetch!(attrs, :name))}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  defp find_or_create_department_for_company(%Company{} = company, department_name) do
    case Repo.get_by(Department, company_id: company.id, name: department_name) do
      %Department{} = department ->
        {:ok, Repo.preload(department, :company)}

      nil ->
        attrs = %{name: department_name, company_id: company.id, is_active: true}

        case create_department(attrs) do
          {:ok, department} ->
            {:ok, department}

          {:error,
           %Ecto.Changeset{errors: [name: {_, [constraint: :unique, constraint_name: _]}]}} ->
            {:ok,
             Repo.get_by!(Department, company_id: company.id, name: department_name)
             |> Repo.preload(:company)}

          {:error, changeset} ->
            {:error, changeset}
        end
    end
  end

  defp maybe_preload_department_company({:ok, %Department{} = department}) do
    {:ok, Repo.preload(department, :company)}
  end

  defp maybe_preload_department_company(result), do: result
end
