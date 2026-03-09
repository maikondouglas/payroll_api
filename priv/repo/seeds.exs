# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     PayrollApi.Repo.insert!(%PayrollApi.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias PayrollApi.Accounts

Accounts.create_user(%{
  name: "Admin Master",
  # Guardamos o e-mail para comunicação
  email: "admin@payroll.com",
  # Usaremos o CPF para o login na API
  cpf: "00011122233",
  password: "password123",
  role: "admin"
})
