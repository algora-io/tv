defmodule AlgoraWeb.HeroComponent do
  use AlgoraWeb, :live_component

  alias Algora.{Library, Events}
  alias AlgoraWeb.Presence

  @impl true
  def render(assigns) do
    ~H"""
    <video
      id={@id}
      phx-hook="VideoPlayer"
      class="video-js vjs-default-skin aspect-video h-full w-full flex-1 overflow-hidden"
    />
    """
  end

  @impl true
  def update(assigns, socket) do
    # TODO: log at regular intervals
    # if socket.current_user && socket.assigns.video.is_live do
    #   schedule_watch_event(:timer.seconds(2))
    # end

    socket =
      case assigns[:video] do
        nil ->
          socket

        video ->
          %{current_user: current_user} = assigns

          Events.log_watched(current_user, video)

          Presence.track_user(video.channel_handle, %{
            id: if(current_user, do: current_user.handle, else: "")
          })

          socket
          |> push_event("play_video", %{
            player_id: assigns.id,
            id: video.id,
            url: video.url,
            title: video.title,
            player_type: Library.player_type(video),
            channel_name: video.channel_name,
            current_time: assigns[:current_time]
          })
      end

    {:ok,
     socket
     |> assign(:id, assigns[:id])}
  end
end
