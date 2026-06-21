defmodule Scout.Pagination do
  @moduledoc false

  @item_keys ~w(items data results searches runs jobs monitors)

  @doc "Walk every page of an offset-paginated endpoint and collect the items."
  def all(client, path, limit \\ 50) do
    do_all(client, path, limit, 0, [])
  end

  defp do_all(client, path, limit, offset, acc) do
    case Scout.Client.request(client, :get, path, params: %{limit: limit, offset: offset}) do
      {:ok, page} ->
        items = extract_items(page)
        acc = acc ++ items

        if length(items) < limit do
          {:ok, acc}
        else
          do_all(client, path, limit, offset + length(items), acc)
        end

      {:error, _} = error ->
        error
    end
  end

  @doc false
  def extract_items(payload) when is_list(payload), do: payload

  def extract_items(payload) when is_map(payload) do
    keyed = Enum.find_value(@item_keys, fn key ->
      case Map.get(payload, key) do
        list when is_list(list) -> list
        _ -> nil
      end
    end)

    keyed || Enum.find_value(payload, [], fn {_k, v} -> if is_list(v), do: v end) || []
  end

  def extract_items(_), do: []
end
