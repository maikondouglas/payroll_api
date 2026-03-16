defmodule PayrollApiWeb.V1.MeControllerTest do
  use PayrollApiWeb.ConnCase, async: true

  alias PayrollApi.Accounts
  alias PayrollApi.Auth.Guardian
  alias PayrollApi.HR
  alias PayrollApi.Organizations

  describe "GET /api/v1/me" do
    test "returns the authenticated user profile with employee data", %{conn: conn} do
      user = create_user(%{role: "employee"})
      department = create_department("Acme Corp", "Engineering")

      {:ok, _employee} =
        HR.create_employee(%{
          registration: "REG-1001",
          job_title: "Backend Engineer",
          admission_date: ~D[2024-02-01],
          birth_date: ~D[1990-07-15],
          department_id: department.id,
          user_id: user.id
        })

      conn = authenticated_conn(conn, user)
      conn = get(conn, ~p"/api/v1/me")

      assert %{
               "id" => user_id,
               "name" => user_name,
               "email" => user_email,
               "cpf" => user_cpf,
               "role" => "employee",
               "employee_profile" => %{
                 "registration" => "REG-1001",
                 "job_title" => "Backend Engineer",
                 "admission_date" => "2024-02-01",
                 "birth_date" => "1990-07-15",
                 "department" => "Engineering",
                 "company" => "Acme Corp"
               }
             } = json_response(conn, 200)

      assert user_id == user.id
      assert user_name == user.name
      assert user_email == user.email
      assert user_cpf == user.cpf
    end

    test "returns null employee fields when authenticated user has no employee profile", %{
      conn: conn
    } do
      user =
        create_user(%{
          role: "admin",
          cpf: "10987654321",
          email: "admin.user@example.com",
          name: "Admin User"
        })

      conn = authenticated_conn(conn, user)
      conn = get(conn, ~p"/api/v1/me")

      assert %{
               "id" => user_id,
               "name" => user_name,
               "email" => user_email,
               "cpf" => user_cpf,
               "role" => "admin",
               "employee_profile" => %{
                 "registration" => nil,
                 "job_title" => nil,
                 "admission_date" => nil,
                 "birth_date" => nil,
                 "department" => nil,
                 "company" => nil
               }
             } = json_response(conn, 200)

      assert user_id == user.id
      assert user_name == user.name
      assert user_email == user.email
      assert user_cpf == user.cpf
    end
  end

  defp authenticated_conn(conn, user) do
    {:ok, token, _claims} = Guardian.encode_and_sign(user)

    put_req_header(conn, "authorization", "Bearer " <> token)
  end

  defp create_user(attrs) do
    unique = System.unique_integer([:positive])

    params =
      Map.merge(
        %{
          name: "Employee User",
          email: "employee.user@example.com",
          cpf: "12345678901",
          password: "password123",
          role: "employee"
        },
        attrs
      )
      |> ensure_unique_email(unique)
      |> ensure_unique_cpf(unique)

    {:ok, user} = Accounts.create_user(params)
    user
  end

  defp ensure_unique_email(%{email: email} = attrs, unique) do
    [local, domain] = String.split(email, "@", parts: 2)
    %{attrs | email: local <> "." <> Integer.to_string(unique) <> "@" <> domain}
  end

  defp ensure_unique_cpf(%{cpf: cpf} = attrs, unique) do
    suffix = Integer.to_string(rem(unique, 100_000)) |> String.pad_leading(5, "0")
    base = String.slice(cpf, 0, 6)
    %{attrs | cpf: base <> suffix}
  end

  defp create_department(company_name, department_name) do
    {:ok, department} = Organizations.find_or_create_department(company_name, department_name)
    department
  end
end
