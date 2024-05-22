defmodule AlgoraWebSocket do
  use WebSockex
  require Logger

  alias Algora.Accounts

  def start_link(%{url: url, video: video}) do
    WebSockex.start_link(url, __MODULE__, %{url: url, video: video})
  end

  def handle_frame({:text, msg}, state) do
    case Jason.decode(msg) do
      {:ok,
       %{
         "action" => "event",
         "payload" => %{
           "connectionIdentifier" => conn_identifier,
           "eventPayload" => %{
             "author" =>
               %{
                 "name" => handle,
                 "displayName" => name,
                 "avatar" => avatar_url,
                 "id" => platform_id
               } = author,
             "bot" => false,
             "contentModifiers" => %{"whisper" => false},
             "text" => _text
           }
         }
       }} ->
        Accounts.create_entity!(%{
          name: name,
          handle: handle,
          avatar_url: avatar_url,
          # HACK:
          platform: String.split(conn_identifier, "-") |> Enum.at(1),
          platform_id: platform_id,
          platform_meta: author
        })

      # TODO: persist & broadcast message
      # TODO: handle missing data?

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
