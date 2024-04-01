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
    <form id="upload-form" phx-submit="upload_videos" phx-change="validate_uploads">
      <.live_file_input upload={@uploads.video} />
      <button type="submit">Upload</button>
    </form>
    <section phx-drop-target={@uploads.video.ref}>
      <%= for entry <- @uploads.video.entries do %>
        <article class="upload-entry">
          <div><%= entry.client_name %></div>
          <progress value={entry.progress} max="100"><%= entry.progress %>%</progress>
          <button
            type="button"
            phx-click="cancel_upload"
            phx-value-ref={entry.ref}
            aria-label="cancel"
          >
            &times;
          </button>
          <%= for err <- upload_errors(@uploads.video, entry) do %>
            <p class="alert alert-danger"><%= error_to_string(err) %></p>
          <% end %>
        </article>
      <% end %>
      <%= for err <- upload_errors(@uploads.video) do %>
        <p class="alert alert-danger"><%= error_to_string(err) %></p>
      <% end %>
    </section>

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
      |> assign(:uploaded_videos, [])
      |> allow_upload(:video, accept: ~w(.mp4), max_entries: 2)

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl true
  def handle_info(
        {Library, %Library.Events.ProcessingQueued{video: video} = status},
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
        {Library, %Library.Events.ProcessingProgressed{video: video} = status},
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
        {Library, %Library.Events.ProcessingCompleted{video: video, url: url} = status},
        socket
      ) do
    {:noreply,
     socket
     |> assign(:status, socket.assigns.status |> Map.put(video.id, status))
     |> stream_insert(:videos, video)
     |> redirect(external: url)}
  end

  def handle_info(
        {Library, %Library.Events.ProcessingFailed{video: video} = status},
        socket
      ) do
    {:noreply,
     socket
     |> assign(:status, socket.assigns.status |> Map.put(video.id, status))
     |> stream_insert(:videos, video)}
  end

  @impl true
  def handle_event("download_video", %{"id" => id}, socket) do
    mp4_video = Library.get_mp4_video(id)

    if mp4_video do
      {:noreply, redirect(socket, external: mp4_video.url)}
    else
      video = Library.get_video!(id)
      send(self(), {Library, %Library.Events.ProcessingQueued{video: video}})

      %{video_id: id}
      |> Workers.MP4Transmuxer.new()
      |> Oban.insert()

      {:noreply, socket}
    end
  end

  def handle_event("upload_videos", _params, socket) do
    uploaded_videos =
      consume_uploaded_entries(socket, :video, fn %{path: path}, entry ->
        video = Library.init_mp4!(entry, path, socket.assigns.current_user)

        send(self(), {Library, %Library.Events.ProcessingQueued{video: video}})

        %{video_id: video.id}
        |> Workers.HLSTransmuxer.new()
        |> Oban.insert()

        {:ok, video}
      end)

    {:noreply,
     socket
     |> update(:uploaded_videos, &(&1 ++ uploaded_videos))
     |> stream(:videos, uploaded_videos)}
  end

  def handle_event("validate_uploads", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("cancel_upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :avatar, ref)}
  end

  defp apply_action(socket, :show, _params) do
    socket |> assign(:page_title, "Studio")
  end

  defp error_to_string(:too_large), do: "Too large"
  defp error_to_string(:not_accepted), do: "You have selected an unacceptable file type"
  defp error_to_string(:too_many_files), do: "You have selected too many files"

  defmodule Status do
    use Phoenix.Component

    def info(%{status: %Library.Events.ProcessingQueued{}} = assigns) do
      ~H"""
      <div>
        Queued for processing...
      </div>
      """
    end

    def info(%{status: %Library.Events.ProcessingProgressed{}} = assigns) do
      ~H"""
      <div>
        Processing your video: <%= @status.stage %>
      </div>
      <div>
        [<%= :erlang.float_to_binary(@status.pct * 100.0, decimals: 0) %>%]
      </div>
      """
    end

    def info(%{status: %Library.Events.ProcessingCompleted{}} = assigns) do
      ~H"""
      <div>
        Ready to download!
      </div>
      """
    end

    def info(%{status: %Library.Events.ProcessingFailed{}} = assigns) do
      ~H"""
      <div>
        Processing failed
      </div>
      <div>
        Attempt: <%= @status.attempt %>/<%= @status.max_attempts %>
      </div>
      """
    end
  end
end
