defmodule AlgoraWeb.StudioLive do
  use AlgoraWeb, :live_view

  alias Algora.{Library, Workers}

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
      <:col :let={{_id, video}}>
        <div class="max-w-xs">
          <.video_entry video={video} />
        </div>
      </:col>
      <:col :let={{_id, video}}>
        <div :if={@progress[video.id]} class="text-sm text-center">
          <div>
            Transmuxing your video to MP4
          </div>
          <div>
            [<%= :erlang.float_to_binary(@progress[video.id] * 100.0,
              decimals: 0
            ) %>%]
          </div>
        </div>
      </:col>
      <:action :let={{_id, video}}>
        <.button phx-click="download_video" phx-value-id={video.id}>Download</.button>
      </:action>
    </.table>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    channel = Library.get_channel!(socket.assigns.current_user)

    if connected?(socket), do: Library.subscribe_to_studio()

    socket =
      socket
      |> assign(:progress, %{})
      |> stream(:videos, Library.list_channel_videos(channel))

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl true
  def handle_info(
        {Library, %Library.Events.TransmuxingProgressed{video: video, pct: pct}},
        socket
      ) do
    {
      :noreply,
      socket
      |> assign(:progress, socket.assigns.progress |> Map.put(video.id, pct))
      |> stream_insert(:videos, video)
    }
  end

  @impl true
  def handle_info(
        {Library, %Library.Events.TransmuxingCompleted{url: url}},
        socket
      ) do
    {:noreply, socket |> redirect(external: url)}
  end

  @impl true
  def handle_event("download_video", %{"id" => id}, socket) do
    video = Library.get_mp4_video(id)

    if video do
      {:noreply, redirect(socket, external: video.url)}
    else
      %{video_id: id}
      |> Workers.Mp4Transmuxer.new()
      |> Oban.insert()

      {:noreply, socket}
    end
  end

  defp apply_action(socket, :show, _params) do
    socket |> assign(:page_title, "Studio")
  end
end
