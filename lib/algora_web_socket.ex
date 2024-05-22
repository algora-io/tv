defmodule AlgoraWebSocket do
  use WebSockex
  require Logger

  def start_link(url) do
    WebSockex.start_link(url, __MODULE__, %{url: url})
  end

  def handle_frame({:text, msg}, state) do
    case Jason.decode(msg) do
      {:ok, action} ->
        Logger.info("Received message: #{inspect(action)}")

      {:error, _reason} ->
        Logger.error("Failed to parse message: #{msg}")
    end

    {:ok, state}
  end

  def handle_disconnect(_reason, state) do
    Logger.error("WebSocket disconnected")
    {:reconnect, state}
  end
end
