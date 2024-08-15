defmodule Algora.Youtube.Chat do
  @youtube_headers [
    {"User-Agent",
     "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.45 Safari/537.36"},
    {"Accept-Language", "en-US"}
  ]

  def get_video_data(urls) do
    urls
    |> Enum.reduce(nil, fn url, acc ->
      case fetch_response(url) do
        {:ok, response} -> response
        _ -> acc
      end
    end)
    |> handle_response()
  end

  def fetch_response(url) do
    HTTPoison.get(url, @youtube_headers)
  end

  defp handle_response(nil), do: {:error, {"Stream not found", 404}}

  defp handle_response(%HTTPoison.Response{status_code: 404}),
    do: {:error, {"Stream not found", 404}}

  defp handle_response(%HTTPoison.Response{status_code: status}) when status != 200,
    do: {:error, {"Failed to fetch stream: #{status}", status}}

  defp handle_response(%HTTPoison.Response{body: body}) do
    case Regex.run(
           ~r/(?:window\s*\[\s*["']ytInitialData["']\s*\]|ytInitialData)\s*=\s*({.+?})\s*;/,
           body
         ) do
      [_, initial_data] ->
        case Regex.run(~r/(?:ytcfg.set)\(({[\s\S]+?})\)\s*;/, body) do
          [_, config_str] ->
            config = Jason.decode!(config_str)

            if Map.has_key?(config, "INNERTUBE_API_KEY") and
                 Map.has_key?(config, "INNERTUBE_CONTEXT") do
              {:ok, %{initial_data: initial_data, config: Map.put(config, "hl", "US")}}
            else
              {:error, {"Failed to load YouTube context", 500}}
            end

          _ ->
            {:error, {"Failed to parse config", 500}}
        end

      _ ->
        {:error, {"Failed to parse initial data", 500}}
    end
  end

  def get_continuation_token(continuation) when is_map(continuation) do
    continuation
    |> Enum.find_value(nil, fn
      {_key, %{"continuation" => continuation_token}} -> continuation_token
      _ -> nil
    end)
  end

  def get_continuation_token(_continuation), do: nil

  def get_id(data) when is_map(data) do
    data
    |> Map.delete("clickTrackingParams")
    |> traverse_map()
  end

  defp traverse_map(map) do
    case Map.to_list(map) do
      [{_action_type, %{"item" => action}}] ->
        case Map.to_list(action) do
          [{_renderer_type, %{"id" => id}}] -> id
          _ -> nil
        end

      _ ->
        nil
    end
  end

  def find_key_value(json_string, key, target_value) do
    case Jason.decode(json_string) do
      {:ok, decoded_json} ->
        find_in_nested(decoded_json, key, target_value)

      {:error, error} ->
        IO.puts("Error decoding JSON: #{inspect(error)}")
    end
  end

  defp find_in_nested(nil, _key, _target_value), do: nil

  defp find_in_nested(map = %{}, key, target_value) do
    Enum.find_value(map, fn
      {^key, ^target_value} -> map
      {_k, v} -> find_in_nested(v, key, target_value)
    end)
  end

  defp find_in_nested([head | tail], key, target_value) do
    find_in_nested(head, key, target_value) || find_in_nested(tail, key, target_value)
  end

  defp find_in_nested(_value, _key, _target_value), do: nil
end
