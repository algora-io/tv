defmodule Algora.Restream do
  def authorize_url(state) do
    query =
      URI.encode_query(
        client_id: client_id(),
        state: state,
        response_type: "code",
        redirect_uri: redirect_uri()
      )

    "https://api.restream.io/login?#{query}"
  end

  def exchange_access_token(opts) do
    code = Keyword.fetch!(opts, :code)
    state = Keyword.fetch!(opts, :state)

    state
    |> fetch_exchange_response(code)
    |> fetch_user_info()
  end

  defp fetch_exchange_response(_state, code) do
    body =
      URI.encode_query(%{
        grant_type: "authorization_code",
        redirect_uri: redirect_uri(),
        code: code
      })

    headers = [
      {"Content-Type", "application/x-www-form-urlencoded"},
      {"Authorization", "Basic " <> Base.encode64("#{client_id()}:#{secret()}")}
    ]

    resp = HTTPoison.post("https://api.restream.io/oauth/token", body, headers)

    with {:ok, %HTTPoison.Response{status_code: 200, body: body}} <- resp,
         %{"access_token" => token, "refresh_token" => refresh_token} <- Jason.decode!(body) do
      {:ok, %{token: token, refresh_token: refresh_token}}
    else
      {:error, %HTTPoison.Error{reason: reason}} -> {:error, reason}
      %{} = resp -> {:error, {:bad_response, resp}}
    end
  end

  defp fetch_user_info({:error, _reason} = error), do: error

  defp fetch_user_info({:ok, %{token: token} = tokens}) do
    headers = [{"Authorization", "Bearer #{token}"}]

    case HTTPoison.get("https://api.restream.io/v2/user/profile", headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, %{info: Jason.decode!(body), tokens: tokens}}

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

    resp = HTTPoison.post("https://api.restream.io/oauth/token", body, headers)

    with {:ok, %HTTPoison.Response{status_code: 200, body: body}} <- resp,
         %{"access_token" => token, "refresh_token" => refresh_token} <- Jason.decode!(body) do
      {:ok, %{token: token, refresh_token: refresh_token}}
    else
      {:error, %HTTPoison.Error{reason: reason}} -> {:error, reason}
      %{} = resp -> {:error, {:bad_response, resp}}
    end
  end

  defp client_id, do: Algora.config([:restream, :client_id])
  defp secret, do: Algora.config([:restream, :client_secret])
  defp redirect_uri, do: "#{AlgoraWeb.Endpoint.url()}/oauth/callbacks/restream"
end
