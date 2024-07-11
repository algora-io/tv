defmodule AlgoraWeb.Websockets.ChatSocket do
  @moduledoc """
  `Phoenix.Socket.Transport` implementation for sending chat messages
  to the client connection.
  """

  @behaviour Phoenix.Socket.Transport

  require Logger

  alias Algora.{Accounts, Library, Chat}

  @base_mount_path "/chat"

  @spec base_mount_path :: String.t()
  def base_mount_path, do: @base_mount_path

  @impl true
  def child_spec(_opts) do
    %{id: Task, start: {Task, :start_link, [fn -> :ok end]}, restart: :transient}
  end

  @impl true
  def connect(%{params: %{"channel_handle" => channel_handle}}) do
    {:ok, %{channel_handle: channel_handle}}
  end

  @impl true
  def init(%{channel_handle: channel_handle}) do
    user = Accounts.get_user_by!(handle: channel_handle)
    channel = Library.get_channel!(user)
    video = Library.get_latest_video(user)

    Library.subscribe_to_channel(channel)
    if video, do: Chat.subscribe_to_room(video)

    {:ok, %{video: video}}
  end

  @impl true
  def handle_in({_message, _opts}, state) do
    {:ok, state}
  end

  @impl true
  def handle_info({Chat, %Chat.Events.MessageSent{message: message}}, state) do
    {:push, {:text, Jason.encode!(message)}, state}
  end

  def handle_info(
        {Library, %Library.Events.LivestreamStarted{video: video}},
        state
      ) do
    if state.video, do: Chat.unsubscribe_to_room(state.video)
    Chat.subscribe_to_room(video)
    {:ok, %{video: video}}
  end

  def handle_info(_message, state) do
    {:ok, state}
  end

  @impl true
  def terminate(_reason, _state) do
    :ok
  end
end
