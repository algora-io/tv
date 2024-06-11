defmodule Algora.ExAwsHttpClient do
  @behaviour ExAws.Request.HttpClient

  require Logger

  def request(method, url, body, headers, http_opts) do
    case http_opts do
      [] -> :noop
      opts -> Logger.debug(inspect({:http_opts, opts}))
    end

    dbg(url)

    with {:ok, resp} <- Finch.build(method, url, headers, body) |> Finch.request(Algora.Finch) do
      {:ok, %{status_code: resp.status, body: resp.body, headers: resp.headers}}
    else
      {:error, reason} ->
        {:error, %{reason: reason}}
    end
  end
end
