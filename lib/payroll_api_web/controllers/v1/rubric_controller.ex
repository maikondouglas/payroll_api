defmodule PayrollApiWeb.V1.RubricController do
  use PayrollApiWeb, :controller

  alias PayrollApi.Payroll
  alias PayrollApi.Payroll.Rubric

  action_fallback PayrollApiWeb.FallbackController

  def index(conn, _params) do
    rubrics = Payroll.list_rubrics()

    conn
    |> put_status(:ok)
    |> json(Enum.map(rubrics, &rubric_to_json/1))
  end

  def show(conn, %{"id" => id}) do
    rubric = Payroll.get_rubric!(id)

    conn
    |> put_status(:ok)
    |> json(rubric_to_json(rubric))
  end

  def create(conn, params) do
    with {:ok, %Rubric{} = rubric} <- Payroll.create_rubric(params) do
      conn
      |> put_status(:created)
      |> json(rubric_to_json(rubric))
    end
  end

  def update(conn, %{"id" => id} = params) do
    rubric = Payroll.get_rubric!(id)
    rubric_params = Map.delete(params, "id")

    with {:ok, %Rubric{} = updated_rubric} <- Payroll.update_rubric(rubric, rubric_params) do
      conn
      |> put_status(:ok)
      |> json(rubric_to_json(updated_rubric))
    end
  end

  def delete(conn, %{"id" => id}) do
    rubric = Payroll.get_rubric!(id)

    with {:ok, %Rubric{}} <- Payroll.delete_rubric(rubric) do
      conn
      |> put_status(:ok)
      |> json(%{"message" => "Rubrica removida com sucesso"})
    end
  end

  defp rubric_to_json(rubric) do
    %{
      "id" => rubric.id,
      "code" => rubric.code,
      "description" => rubric.description,
      "category" => rubric.category,
      "inserted_at" => rubric.inserted_at,
      "updated_at" => rubric.updated_at
    }
  end
end
