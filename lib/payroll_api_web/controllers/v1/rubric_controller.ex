defmodule PayrollApiWeb.V1.RubricController do
  use PayrollApiWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias PayrollApi.Payroll
  alias PayrollApi.Payroll.Rubric
  alias PayrollApiWeb.Schemas.{ErrorResponse, RubricBulkUpsertRequest, RubricBulkUpsertResponse}

  action_fallback PayrollApiWeb.FallbackController

  tags(["Admin - Rubrics"])

  operation(:create,
    summary: "Create or update rubrics in bulk",
    description:
      "Receives a JSON array of rubrics and performs bulk create or update using the rubric code as the conflict key.",
    security: [%{"bearer" => []}],
    request_body: {"Rubric list", "application/json", RubricBulkUpsertRequest},
    responses: [
      created: {"Rubrics imported", "application/json", RubricBulkUpsertResponse},
      bad_request: {"Invalid payload or import failure", "application/json", ErrorResponse},
      unauthorized: {"Missing or invalid token", "application/json", ErrorResponse}
    ]
  )

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
    case PayrollApi.Payroll.create_rubrics_in_bulk(Enum.map(rubrics_params, &normalize_rubric_params/1)) do
      {count, nil} ->
        conn
        |> put_status(:created)
        |> json(%{message: "#{count} rubrics imported or updated successfully", count: count})

      {:error, reason} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: "Failed to import rubrics in bulk", details: reason})
    end
  end

  # 2. Captura quando vier um único objeto padrão do Phoenix (ex: {"rubric": {...}})
  def create(conn, %{"rubric" => rubric_params}) do
    with {:ok, %Rubric{} = rubric} <- PayrollApi.Payroll.create_rubric(normalize_rubric_params(rubric_params)) do
      conn
      |> put_status(:created)
      |> json(%{message: "Rubric created successfully", rubric: rubric_to_json(rubric)})
    end
  end

  # 3. (Opcional) Captura quando vier um único objeto solto (ex: {"code": "001", ...})
  def create(conn, rubric_params) when is_map(rubric_params) do
    with {:ok, %Rubric{} = rubric} <- PayrollApi.Payroll.create_rubric(normalize_rubric_params(rubric_params)) do
      conn
      |> put_status(:created)
      |> json(%{message: "Rubric created successfully", rubric: rubric_to_json(rubric)})
    end
  end

  def update(conn, %{"id" => id} = params) do
    rubric = Payroll.get_rubric!(id)
    rubric_params = params |> Map.delete("id") |> normalize_rubric_params()

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
      |> json(%{"message" => "Rubric deleted successfully"})
    end
  end

  defp rubric_to_json(rubric) do
    %{
      "id" => rubric.id,
      "code" => rubric.code,
      "description" => rubric.description,
      "category" => translate_category(rubric.category),
      "inserted_at" => rubric.inserted_at,
      "updated_at" => rubric.updated_at
    }
  end

  defp normalize_rubric_params(%{"category" => category} = params) do
    Map.put(params, "category", normalize_category(category))
  end

  defp normalize_rubric_params(params), do: params

  defp normalize_category("earning"), do: "provento"
  defp normalize_category("deduction"), do: "desconto"
  defp normalize_category("charge"), do: "encargo"
  defp normalize_category("informational"), do: "informativa"
  defp normalize_category(category), do: category

  defp translate_category("provento"), do: "earning"
  defp translate_category("desconto"), do: "deduction"
  defp translate_category("encargo"), do: "charge"
  defp translate_category("informativa"), do: "informational"
  defp translate_category(category), do: category
end
