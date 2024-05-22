defmodule Algora.Restream do
  def authorize_url(return_to \\ nil) do
    redirect_query = if return_to, do: URI.encode_query(return_to: return_to)

    query =
      URI.encode_query(
        client_id: client_id(),
        state: random_string(),
        response_type: "code",
        redirect_uri: "#{AlgoraWeb.Endpoint.url()}/oauth/callbacks/restream?#{redirect_query}"
      )

    "https://api.restream.io/login?#{query}"
  end

  def exchange_access_token(opts) do
    code = Keyword.fetch!(opts, :code)
    redirect_uri = Application.get_env(:algora, :restream_redirect_uri)

    body =
      URI.encode_query(%{
        grant_type: "authorization_code",
        redirect_uri: redirect_uri,
        code: code
      })

    headers = [
      {"Content-Type", "application/x-www-form-urlencoded"},
      {"Authorization", "Basic " <> Base.encode64("#{client_id()}:#{secret()}")}
    ]

    case HTTPoison.post("https://api.restream.io/oauth/token", body, headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, Jason.decode!(body)}

      {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
        {:error, {status_code, body}}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end

  def refresh_access_token(refresh_token) do
    body =
      URI.encode_query(%{
        grant_type: "refresh_token",
        refresh_token: refresh_token
      })

    headers = [
      {"Content-Type", "application/x-www-form-urlencoded"},
      {"Authorization", "Basic " <> Base.encode64("#{client_id()}:#{secret()}")}
    ]

    case HTTPoison.post("https://api.restream.io/oauth/token", body, headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, Jason.decode!(body)}

      {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
        {:error, {status_code, body}}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end

  def random_string do
    binary = <<
      System.system_time(:nanosecond)::64,
      :erlang.phash2({node(), self()})::16,
      :erlang.unique_integer()::16
    >>

    binary
    |> Base.url_encode64()
    |> String.replace(["/", "+"], "-")
  end

  defp client_id, do: Algora.config([:restream, :client_id])
  defp secret, do: Algora.config([:restream, :client_secret])
end
