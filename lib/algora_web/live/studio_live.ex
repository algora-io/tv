defmodule AlgoraWeb.StudioLive do
  use AlgoraWeb, :live_view

  alias Algora.{Library, Workers}
  alias AlgoraWeb.LayoutComponent
  alias AlgoraWeb.StudioLive.UploadFormComponent

  @impl true
  def render(assigns) do
    ~H"""
    <.header class="p-4 sm:p-6 lg:p-8">
      Studio
      <:actions>
        <.link patch={~p"/channel/studio/upload"}>
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
        <div :if={@status[video.id]} class="text-sm text-center">
          <AlgoraWeb.StudioLive.Status.info status={@status[video.id]} />
        </div>
      </:col>
      <:action :let={{_id, video}}>
        <.button
          phx-click="download_video"
          phx-value-id={video.id}
          disabled={!is_nil(@status[video.id])}
          class={"#{if(!is_nil(@status[video.id]), do: "cursor-wait opacity-50")}"}
        >
          Download
        </.button>
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
      |> assign(:status, %{})
      |> stream(:videos, Library.list_channel_videos(channel))

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl true
  def handle_info(
        {Library, %Library.Events.TransmuxingQueued{video: video} = status},
        socket
      ) do
    {
      :noreply,
      socket
      |> assign(:status, socket.assigns.status |> Map.put(video.id, status))
      |> stream_insert(:videos, video)
    }
  end

  def handle_info(
        {Library, %Library.Events.TransmuxingProgressed{video: video} = status},
        socket
      ) do
    {
      :noreply,
      socket
      |> assign(:status, socket.assigns.status |> Map.put(video.id, status))
      |> stream_insert(:videos, video)
    }
  end

  def handle_info(
        {Library, %Library.Events.TransmuxingCompleted{url: url}},
        socket
      ) do
    {:noreply, socket |> redirect(external: url)}
  end

  @impl true
  def handle_event("download_video", %{"id" => id}, socket) do
    mp4_video = Library.get_mp4_video(id)

    if mp4_video do
      {:noreply, redirect(socket, external: mp4_video.url)}
    else
      video = Library.get_video!(id)
      send(self(), {Library, %Library.Events.TransmuxingQueued{video: video}})

      %{video_id: id}
      |> Workers.Mp4Transmuxer.new()
      |> Oban.insert()

      {:noreply, socket}
    end
  end

  defp apply_action(socket, :show, _params) do
    socket |> assign(:page_title, "Studio")
  end

  defp apply_action(socket, :upload, _params) do
    socket
    |> assign(:page_title, "Upload Video")
    |> assign(:video, %Library.Video{})
    |> show_upload_modal()
  end

  defp show_upload_modal(socket) do
    LayoutComponent.show_modal(UploadFormComponent, %{
      id: :upload,
      confirm: {"Save", type: "submit", form: "video-form"},
      patch: channel_path(socket.assigns.current_user),
      video: socket.assigns.video,
      title: socket.assigns.page_title,
      current_user: socket.assigns.current_user
    })

    socket
  end

  defmodule Status do
    use Phoenix.Component

    def info(%{status: %Library.Events.TransmuxingQueued{}} = assigns) do
      ~H"""
      <div>
        Queued for processing...
      </div>
      """
    end

    def info(%{status: %Library.Events.TransmuxingProgressed{pct: _pct}} = assigns) do
      ~H"""
      <div>
        Transmuxing into MP4...
      </div>
      <div>
        [<%= :erlang.float_to_binary(@status.pct * 100.0, decimals: 0) %>%]
      </div>
      """
    end

    def info(%{status: %Library.Events.TransmuxingCompleted{}} = assigns) do
      ~H"""
      <div>
        Ready to download!
      </div>
      """
    end
  end
end
