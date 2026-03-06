defmodule PayrollApi.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  alias PayrollApi.HR.Employee

  schema "users" do
    field :name, :string
    field :email, :string
    field :cpf, :string
    field :role, :string, default: "employee"
    field :password, :string, virtual: true
    field :password_hash, :string

    # Relacionamento com Employee (1:1)
    has_one :employee, Employee, on_delete: :delete_all

    timestamps()
  end

  def changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :email, :cpf, :role, :password])
    |> validate_required([:name, :email, :cpf, :password])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "formato inválido")
    |> validate_length(:cpf, is: 11, message: "deve conter exatamente 11 dígitos")
    |> validate_length(:password, min: 6)
    |> unique_constraint(:email)
    |> unique_constraint(:cpf)
    |> put_pass_hash()
  end

  defp put_pass_hash(%Ecto.Changeset{valid?: true, changes: %{password: password}} = changeset) do
    change(changeset, password_hash: Bcrypt.hash_pwd_salt(password))
  end

  defp put_pass_hash(changeset), do: changeset
end
