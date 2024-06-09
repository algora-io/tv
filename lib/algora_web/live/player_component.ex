defmodule AlgoraWeb.PlayerComponent do
  use AlgoraWeb, :live_component

  alias Algora.{Library, Events}

  @impl true
  def render(assigns) do
    ~H"""
    <video
      id={@id}
      phx-hook="VideoPlayer"
      class="video-js vjs-default-skin aspect-video h-full w-full flex-1 lg:rounded-2xl overflow-hidden"
      controls
    />
    """
  end

  @impl true
  def update(assigns, socket) do
    # TODO: log at regular intervals
    # if socket.assigns.current_user && socket.assigns.video.is_live do
    #   schedule_watch_event(:timer.seconds(2))
    # end

    # TODO: track presence

    socket =
      case assigns[:video] do
        nil ->
          socket

        video ->
          Events.log_watched(assigns.current_user, video)

          socket
          |> push_event("play_video", %{
            player_id: assigns.id,
            id: video.id,
            url: video.url,
            title: video.title,
            player_type: Library.player_type(video),
            channel_name: video.channel_name
          })
      end

    {:ok,
     socket
     |> assign(:id, assigns[:id])}
  end
end
