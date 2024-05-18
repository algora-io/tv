defmodule Algora.Restream do
  def restream_authorize_url() do
    state = random_string()
    client_id = Application.get_env(:algora, :restream_client_id)
    redirect_uri = Application.get_env(:algora, :restream_redirect_uri)

    "https://api.restream.io/login?response_type=code&client_id=#{client_id}&redirect_uri=#{redirect_uri}&state=#{state}"
  end

  def exchange_access_token(opts) do
    code = Keyword.fetch!(opts, :code)
    state = Keyword.fetch!(opts, :state)
    client_id = Application.get_env(:algora, :restream_client_id)
    client_secret = Application.get_env(:algora, :restream_client_secret)
    redirect_uri = Application.get_env(:algora, :restream_redirect_uri)

    body = URI.encode_query(%{
      grant_type: "authorization_code",
      redirect_uri: redirect_uri,
      code: code
    })

    headers = [
      {"Content-Type", "application/x-www-form-urlencoded"},
      {"Authorization", "Basic " <> Base.encode64("#{client_id}:#{client_secret}")}
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
    client_id = Application.get_env(:algora, :restream_client_id)
    client_secret = Application.get_env(:algora, :restream_client_secret)

    body = URI.encode_query(%{
      grant_type: "refresh_token",
      refresh_token: refresh_token
    })

    headers = [
      {"Content-Type", "application/x-www-form-urlencoded"},
      {"Authorization", "Basic " <> Base.encode64("#{client_id}:#{client_secret}")}
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

  defp random_string do
    :crypto.strong_rand_bytes(16) |> Base.url_encode64 |> binary_part(0, 16)
  end
end
