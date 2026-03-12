# Auto-loaded in `iex -S mix`.

alias PayrollApi.Repo
import Ecto.Query

alias PayrollApi.Accounts.User
alias PayrollApi.HR.Employee
alias PayrollApi.Payroll.{Payslip, Rubric}
alias PayrollApi.Communication.Announcement

defmodule IExHelpers do
	import Ecto.Query

	alias PayrollApi.Repo
	alias PayrollApi.Accounts.User
	alias PayrollApi.HR.Employee
	alias PayrollApi.Payroll.{Payslip, Rubric}
	alias PayrollApi.Communication.Announcement

	def users, do: Repo.all(User)

	def admins do
		User
		|> where([u], u.role == "admin")
		|> Repo.all()
	end

	def employees, do: Repo.all(Employee)
	def rubrics, do: Repo.all(Rubric)
	def announcements, do: Repo.all(Announcement)
	def payslips, do: Repo.all(Payslip)
end

import IExHelpers
