defmodule AlgoraWeb.HomeLive do
  use AlgoraWeb, :live_view
  require Logger

  alias Algora.{Library, Storage}

  def render(assigns) do
    ~H"""
    <.playlist id="playlist" videos={@streams.videos} />
    """
  end

  def mount(_map, _session, socket) do
    if connected?(socket) do
      Library.subscribe_to_livestreams()
    end

    videos = Library.list_videos(150)

    {:ok, socket |> stream(:videos, videos)}
  end

  def handle_params(params, _url, socket) do
    {:noreply, socket |> apply_action(socket.assigns.live_action, params)}
  end

  def handle_info(
        {Storage, %Library.Events.ThumbnailsGenerated{video: video}},
        socket
      ) do
    {:noreply,
     if video.user_id == socket.assigns.channel.user_id do
       socket
       |> stream_insert(:videos, video, at: 0)
     else
       socket
     end}
  end

  def handle_info(
        {Library, %Library.Events.LivestreamStarted{video: video}},
        socket
      ) do
    %{channel: channel} = socket.assigns

    {:noreply,
     if video.user_id == channel.user_id do
       socket
       |> assign(channel: %{channel | is_live: true})
       |> stream_insert(:videos, video, at: 0)
     else
       socket
     end}
  end

  def handle_info(
        {Library, %Library.Events.LivestreamEnded{video: video}},
        socket
      ) do
    %{channel: channel} = socket.assigns

    {:noreply,
     if video.user_id == channel.user_id do
       socket
       |> assign(channel: %{channel | is_live: false})
       |> stream_insert(:videos, video)
     else
       socket
     end}
  end

  def handle_info({Library, _}, socket), do: {:noreply, socket}

  defp apply_action(socket, :show, _params) do
    socket
    |> assign(:page_title, nil)
    |> assign(:video, nil)
  end
end
