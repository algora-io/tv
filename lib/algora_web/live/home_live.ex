defmodule AlgoraWeb.HomeLive do
  use AlgoraWeb, :live_view
  require Logger

  alias Algora.Library

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

  def handle_info({Library, _}, socket), do: {:noreply, socket}

  defp apply_action(socket, :show, _params) do
    socket
    |> assign(:page_title, nil)
    |> assign(:video, nil)
  end
end
