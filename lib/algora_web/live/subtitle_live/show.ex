defmodule AlgoraWeb.SubtitleLive.Show do
  use AlgoraWeb, :live_view

  alias Algora.Library
  alias AlgoraWeb.PlayerLive

  @impl true
  def mount(%{"video_id" => video_id}, _session, socket) do
    video = Library.get_video!(video_id)

    if connected?(socket), do: PlayerLive.subscribe()

    {:ok, socket |> assign(:video, video)}
  end

  @impl true
  def handle_info({PlayerLive, :ready}, socket) do
    PlayerLive.broadcast!({:play, %{video: socket.assigns.video, params: socket.assigns.params}})
    {:noreply, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:subtitle, Library.get_subtitle!(id))}
  end

  defp page_title(:show), do: "Show Subtitle"
  defp page_title(:edit), do: "Edit Subtitle"
end
