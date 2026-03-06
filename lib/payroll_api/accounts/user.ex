defmodule PayrollApi.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :name, :string
    field :email, :string # <-- E-mail volta para cá
    field :cpf, :string   # <-- CPF continua aqui
    field :role, :string, default: "employee"
    field :password, :string, virtual: true
    field :password_hash, :string

    timestamps()
  end

  def changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :email, :cpf, :role, :password]) # Inclui os dois no cast
    |> validate_required([:name, :email, :cpf, :password])  # Exige os dois
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "formato inválido")
    |> validate_length(:cpf, is: 11, message: "deve conter exatamente 11 dígitos")
    |> validate_length(:password, min: 6)
    |> unique_constraint(:email) # Garante e-mail único
    |> unique_constraint(:cpf)   # Garante CPF único
    |> put_pass_hash()
  end

  defp put_pass_hash(%Ecto.Changeset{valid?: true, changes: %{password: password}} = changeset) do
    change(changeset, password_hash: Bcrypt.hash_pwd_salt(password))
  end

  defp put_pass_hash(changeset), do: changeset
end
