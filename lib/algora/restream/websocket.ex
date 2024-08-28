defmodule Algora.Restream.Websocket do
  use WebSockex
  require Logger

  alias Algora.{Accounts, Chat, Library}

  def start_link(%{url: url, video: video, user: user} = opts) do
    restart = opts[:restart] || 0

    Logger.info("Starting WebSocket: #{video.id} (restart: #{restart})")

    WebSockex.start_link(url, __MODULE__, %{
      url: url,
      video: video,
      user: user,
      restart: restart,
      terminated: false
    })
  end

  def start_link(video_id) do
    video = Library.get_video!(video_id)
    user = Accounts.get_user!(video.user_id)
    url = Accounts.get_restream_ws_url(user)

    start_link(%{url: url, video: video, user: user})
  end

  def handle_info(:restart, state) do
    {:close, state}
  end

  def handle_info(:terminate, state) do
    {:close, %{state | terminated: true}}
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

  def handle_connect(_conn, state) do
    if state.restart == 0 do
      Logger.info("WebSocket connected: #{state.video.id} (pid: #{:erlang.pid_to_list(self())})")
    else
      Logger.info(
        "WebSocket reconnected: #{state.video.id} (pid: #{:erlang.pid_to_list(self())}, restart: #{state.restart})"
      )
    end

    {:ok, %{state | restart: 0}}
  end

  def handle_disconnect(reason, state) do
    Logger.error("WebSocket disconnected: #{state.video.id} (reason: #{inspect(reason)})")

    if state.terminated do
      Logger.info("Terminating WebSocket: #{state.video.id}")
    else
      Logger.info("Restarting WebSocket: #{state.video.id}")
      :timer.sleep(:timer.seconds(min(2 ** state.restart, 60)))
      restart_socket(state)
    end

    {:ok, state}
  end

  defp restart_socket(state) do
    url = Accounts.get_restream_ws_url(state.user)
    state = %{state | restart: state.restart + 1, url: url || state.url}

    Task.Supervisor.start_child(
      Algora.TaskSupervisor,
      fn -> Algora.Restream.Websocket.start_link(state) end,
      restart: :transient
    )
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
