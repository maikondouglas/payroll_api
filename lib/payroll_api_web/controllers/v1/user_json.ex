defmodule PayrollApiWeb.V1.UserJSON do
  alias PayrollApi.Accounts.User
  alias PayrollApi.HR.Employee

  @doc """
  Renders a list of users.
  """
  def index(%{users: users}) do
    %{data: for(user <- users, do: data(user))}
  end

  @doc """
  Renders a single user.
  """
  def show(%{user: user}) do
    %{data: data(user)}
  end

  @doc """
  Renders the authenticated user profile.
  """
  def me(%{user: user}) do
    profile(user)
  end

  defp data(%User{} = user) do
    %{
      id: user.id,
      name: user.name,
      email: user.email,
      password_hash: user.password_hash,
      role: user.role
    }
  end

  defp profile(%User{} = user) do
    %{
      id: user.id,
      name: user.name,
      email: user.email,
      cpf: user.cpf,
      role: user.role,
      employee_profile: employee_profile(user.employee)
    }
  end

  defp employee_profile(%Employee{} = employee) do
    %{
      registration: employee.registration,
      job_title: employee.job_title,
      admission_date: format_date(employee.admission_date),
      birth_date: format_date(employee.birth_date)
    }
  end

  defp employee_profile(_employee) do
    %{
      registration: nil,
      job_title: nil,
      admission_date: nil,
      birth_date: nil
    }
  end

  defp format_date(%Date{} = date), do: Date.to_iso8601(date)
  defp format_date(_date), do: nil
end
