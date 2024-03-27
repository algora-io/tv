defmodule AlgoraWeb.StudioLive do
  use AlgoraWeb, :live_view

  alias Algora.Library

  @impl true
  def render(assigns) do
    ~H"""
    <.header class="p-4 sm:p-6 lg:p-8">
      Studio
      <:actions>
        <.link patch={~p"/studio/upload"}>
          <.button>Upload video</.button>
        </.link>
      </:actions>
    </.header>

    <.table id="videos" rows={@streams.videos}>
      <:col :let={{id, video}} label="">
        <div class="max-w-xs">
          <.video_entry video={video} />
        </div>
      </:col>
      <:action :let={{_id, video}}>
        <.link patch={~p"/videos/#{video.id}/videos/#{video}/edit"}>Download</.link>
      </:action>
    </.table>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    channel = Library.get_channel!(socket.assigns.current_user)
    socket = socket |> stream(:videos, Library.list_channel_videos(channel))
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :show, _params) do
    socket |> assign(:page_title, "Studio")
  end
end
