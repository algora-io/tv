defmodule AlgoraWebSocket do
  use WebSockex
  require Logger

  alias Algora.{Accounts, Chat}

  def start_link(%{url: url, video: video}) do
    WebSockex.start_link(url, __MODULE__, %{url: url, video: video})
  end

  def handle_frame({:text, msg}, state) do
    case Jason.decode(msg) do
      {:ok, action} ->
        handle_action(action, state)

      {:error, _reason} ->
        Logger.error("Failed to parse message: #{msg}")
        {:ok, state}
    end
  end

  def handle_disconnect(_reason, state) do
    Logger.error("WebSocket disconnected")
    {:reconnect, state}
  end

  defp handle_action(
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
               "text" => body
             }
           }
         },
         state
       ) do
    entity =
      Accounts.get_or_create_entity!(%{
        name: name,
        handle: handle,
        avatar_url: avatar_url,
        # HACK:
        platform: String.split(conn_identifier, "-") |> Enum.at(1),
        platform_id: platform_id,
        platform_meta: author
      })

    {:ok, message} = Chat.create_message(entity, state.video, %{body: body})

    # HACK:
    message = Chat.get_message!(message.id)

    Chat.broadcast_message_sent!(message)

    {:ok, state}
  end

  defp handle_action(action, state) do
    Logger.info("Received message: #{inspect(action)}")
    {:ok, state}
  end
end
