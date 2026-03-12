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

  # def create(conn, params) do
  #   with {:ok, %Rubric{} = rubric} <- Payroll.create_rubric(params) do
  #     conn
  #     |> put_status(:created)
  #     |> json(rubric_to_json(rubric))
  #   end
  # end
  # 1. Captura quando o Insomnia enviar um Array JSON (lista de rubricas)
  def create(conn, %{"_json" => rubrics_params}) when is_list(rubrics_params) do
    # Chama a função de contexto que cria várias de uma vez
    case PayrollApi.Payroll.create_rubrics_in_bulk(rubrics_params) do
      {count, nil} ->
        conn
        |> put_status(:created)
        |> json(%{message: "#{count} rubricas importadas/atualizadas com sucesso!"})

      {:error, reason} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: "Falha ao importar rubricas em lote", details: reason})
    end
  end

  # 2. Captura quando vier um único objeto padrão do Phoenix (ex: {"rubric": {...}})
  def create(conn, %{"rubric" => rubric_params}) do
    with {:ok, %Rubric{} = rubric} <- PayrollApi.Payroll.create_rubric(rubric_params) do
      conn
      |> put_status(:created)
      # Aqui você pode chamar a sua view render("show.json", rubric: rubric) ou devolver json puro
      |> json(%{message: "Rubrica criada com sucesso", rubric: rubric})
    end
  end

  # 3. (Opcional) Captura quando vier um único objeto solto (ex: {"code": "001", ...})
  def create(conn, rubric_params) when is_map(rubric_params) do
    with {:ok, %Rubric{} = rubric} <- PayrollApi.Payroll.create_rubric(rubric_params) do
      conn
      |> put_status(:created)
      |> json(%{message: "Rubrica criada com sucesso", rubric: rubric})
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
