defmodule Algora.Restream.Websocket do
  use WebSockex
  require Logger

  alias Algora.{Accounts, Chat}

  def start_link(%{url: url, video: video}) do
    WebSockex.start_link(url, __MODULE__, %{url: url, video: video})
  end

  def handle_frame({:text, msg}, state) do
    case Jason.decode(msg) do
      {:ok, %{"action" => "event", "payload" => payload}} ->
        handle_payload(payload, state)

      {:ok, message} ->
        Logger.info("Received message: #{inspect(message)}")
        {:ok, state}

      {:error, _reason} ->
        Logger.error("Failed to parse message: #{msg}")
        {:ok, state}
    end
  end

  def handle_disconnect(_reason, state) do
    Logger.error("WebSocket disconnected: #{state.video.id}")
    {:reconnect, state}
  end

  defp handle_payload(%{"eventPayload" => %{"contentModifiers" => %{"whisper" => true}}}, state) do
    {:ok, state}
  end

  defp handle_payload(%{"eventPayload" => %{"author" => author, "text" => body}} = payload, state) do
    entity =
      Accounts.get_or_create_entity!(%{
        name: get_name(author),
        handle: get_handle(author),
        avatar_url: author["avatar"],
        platform: get_platform(payload),
        platform_id: author["id"],
        platform_meta: author
      })

    case Chat.create_message(entity, state.video, %{body: body}) do
      {:ok, message} ->
        # HACK:
        message = Chat.get_message!(message.id)
        Chat.broadcast_message_sent!(message)

      _error ->
        Logger.error("Failed to persist payload: #{inspect(payload)}")
    end

    {:ok, state}
  end

  defp handle_payload(payload, state) do
    Logger.info("Received payload: #{inspect(payload)}")
    {:ok, state}
  end

  defp get_platform(%{"connectionIdentifier" => identifier}) do
    parts = String.split(identifier, "-")

    case parts do
      [_prefix, platform | _rest] ->
        platform

      _ ->
        Logger.error("Failed to extract platform: #{identifier}")
        "unknown"
    end
  end

  defp get_platform(_action), do: "unknown"

  defp get_handle(%{"username" => username}), do: username
  defp get_handle(%{"displayName" => displayName}), do: Slug.slugify(displayName)
  defp get_handle(%{"id" => id}), do: id

  defp get_name(%{"displayName" => displayName}), do: displayName
  defp get_name(author), do: get_handle(author)
end
