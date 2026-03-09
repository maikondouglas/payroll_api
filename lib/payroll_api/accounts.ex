defmodule PayrollApi.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias PayrollApi.Repo

  alias PayrollApi.Accounts.User

  @doc """
  Returns the list of users.

  ## Examples

      iex> list_users()
      [%User{}, ...]

  """
  def list_users do
    Repo.all(User)
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id), do: Repo.get!(User, id)

  @doc """
  Gets a single user by CPF.

  Returns nil if the User does not exist.

  ## Examples

      iex> get_user_by_cpf("12345678901")
      %User{}

      iex> get_user_by_cpf("00000000000")
      nil

  """
  def get_user_by_cpf(cpf), do: Repo.get_by(User, cpf: cpf)

  @doc """
  Creates a user.

  ## Examples

      iex> create_user(%{field: value})
      {:ok, %User{}}

      iex> create_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_user(attrs) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a user.

  ## Examples

      iex> update_user(user, %{field: new_value})
      {:ok, %User{}}

      iex> update_user(user, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_user(%User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a user.

  ## Examples

      iex> delete_user(user)
      {:ok, %User{}}

      iex> delete_user(user)
      {:error, %Ecto.Changeset{}}

  """
  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.

  ## Examples

      iex> change_user(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user(%User{} = user, attrs \\ %{}) do
    User.changeset(user, attrs)
  end

  @doc """
  Authenticates a user by email and password.

  ## Examples

      iex> authenticate_user("user@example.com", "password123")
      {:ok, %User{}}

      iex> authenticate_user("user@example.com", "wrongpassword")
      {:error, :invalid_credentials}

  """
  def authenticate_user(email, password) when is_binary(email) and is_binary(password) do
    case Repo.get_by(User, email: email) do
      nil ->
        # Perform a dummy hash check to prevent timing attacks
        Bcrypt.no_user_verify()
        {:error, :invalid_credentials}

      user ->
        if Bcrypt.verify_pass(password, user.password_hash) do
          {:ok, user}
        else
          {:error, :invalid_credentials}
        end
    end
  end

  def authenticate_user(_, _), do: {:error, :invalid_credentials}

  @doc """
  Authenticates a user by CPF and password.

  ## Examples

      iex> authenticate_user("12345678901", "password123")
      {:ok, %User{}}

      iex> authenticate_user("12345678901", "wrongpassword")
      {:error, :invalid_credentials}

  """
  def authenticate_by_cpf(cpf, password) when is_binary(cpf) and is_binary(password) do
    case Repo.get_by(User, cpf: cpf) do
      nil ->
        # Perform a dummy hash check to prevent timing attacks
        Bcrypt.no_user_verify()
        {:error, :invalid_credentials}

      user ->
        if Bcrypt.verify_pass(password, user.password_hash) do
          {:ok, user}
        else
          {:error, :invalid_credentials}
        end
    end
  end

  def authenticate_by_cpf(_, _), do: {:error, :invalid_credentials}
end
