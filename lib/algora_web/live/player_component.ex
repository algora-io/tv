defmodule AlgoraWeb.PlayerComponent do
  use AlgoraWeb, :live_component

  alias Algora.{Library, Events}
  alias AlgoraWeb.Presence

  @impl true
  def render(assigns) do
    ~H"""
    <div class="relative">
      <video
        id={@id}
        phx-hook="VideoPlayer"
        class="h-full w-full flex-1 rounded-lg lg:rounded-2xl overflow-hidden"
        controls
        data-media-player
      />
      <%= if @show_muted_overlay do %>
        <div class="muted-overlay absolute top-0 left-0 w-full h-full flex items-center justify-center bg-black bg-opacity-50 cursor-pointer">
          <svg class="w-16 h-16 text-white" fill="currentColor" viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg">
            <path fill-rule="evenodd" d="M9.383 3.076A1 1 0 0110 4v12a1 1 0 01-1.707.707L4.586 13H2a1 1 0 01-1-1V8a1 1 0 011-1h2.586l3.707-3.707a1 1 0 011.09-.217zM12.293 7.293a1 1 0 011.414 0L15 8.586l1.293-1.293a1 1 0 111.414 1.414L16.414 10l1.293 1.293a1 1 0 01-1.414 1.414L15 11.414l-1.293 1.293a1 1 0 01-1.414-1.414L13.586 10l-1.293-1.293a1 1 0 010-1.414z" clip-rule="evenodd" />
          </svg>
        </div>
      <% end %>
    </div>
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
            is_live: video.is_live,
            player_id: assigns.id,
            id: video.id,
            url: video.url,
            title: video.title,
            poster: video.thumbnail_url,
            player_type: Library.player_type(video),
            channel_name: video.channel_name,
            current_time: assigns[:current_time] || 0
          })
      end

    {:ok,
     socket
     |> assign(:id, assigns[:id])
     |> assign(:show_muted_overlay, true)}
  end

  @impl true
  def handle_event("mute_toggled", %{"muted" => muted}, socket) do
    {:noreply, assign(socket, :show_muted_overlay, muted)}
  end
end