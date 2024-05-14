defmodule AlgoraWebSocket do
  use WebSockex

  @url "wss://chat.api.restream.io/ws?accessToken=#{System.get_env("ACCESS_TOKEN")}"

  def start_link(video_id) do
    WebSockex.start_link(@url, __MODULE__, %{video_id: video_id}, name: via_tuple(video_id))
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

  defp via_tuple(video_id), do: {:via, Registry, {AlgoraWebSocketRegistry, video_id}}
end
