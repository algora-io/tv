defmodule Algora.Restream.Websocket do
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
    Logger.error("WebSocket disconnected: #{state.video.id}")
    {:reconnect, state}
  end

  defp handle_action(
         %{
           "action" => "event",
           "payload" => %{
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
         } = action,
         state
       ) do
    entity =
      Accounts.get_or_create_entity!(%{
        name: name,
        handle: handle,
        avatar_url: avatar_url,
        platform: get_platform(action),
        platform_id: platform_id,
        platform_meta: author
      })

    case Chat.create_message(entity, state.video, %{body: body}) do
      {:ok, message} ->
        # HACK:
        message = Chat.get_message!(message.id)
        Chat.broadcast_message_sent!(message)

      _error ->
        Logger.error("Failed to persist message: #{inspect(action)}")
    end

    {:ok, state}
  end

  defp handle_action(action, state) do
    Logger.info("Received message: #{inspect(action)}")
    {:ok, state}
  end

  defp get_platform(%{"payload" => %{"connectionIdentifier" => identifier}}) do
    parts = String.split(identifier, "-")

    case parts do
      [_prefix, platform, _suffix] ->
        platform

      _ ->
        Logger.error("Failed to extract platform: #{identifier}")
        "unknown"
    end
  end

  defp get_platform(_action), do: "unknown"
end
