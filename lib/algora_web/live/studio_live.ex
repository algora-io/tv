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
      <:col :let={{_id, video}} label="Video">
        <div class="flex items-center gap-4 max-w-xl">
          <.video_thumbnail
            video={video}
            class="shrink-0 rounded-lg w-full max-w-[12rem] pointer-events-none"
          />
          <div class="max-w-md">
            <.link
              class="font-medium text-white text-lg truncate hover:underline"
              navigate={~p"/#{video.channel_handle}/#{video.id}"}
            >
              <%= video.title %>
            </.link>
            <div :if={!@status[video.id]} class="h-10">
              <div class="group-hover:hidden flex items-center gap-1.5 pt-1">
                <Heroicons.chat_bubble_bottom_center_text class="h-5 w-5 text-gray-300" />
                <div class="text-gray-100 text-base font-medium">
                  <%= video.messages_count %>
                </div>
              </div>
              <div class="hidden group-hover:flex items-center gap-1 -ml-1">
                <button
                  phx-click="download_video"
                  phx-value-id={video.id}
                  class="text-gray-100 hover:text-white p-1 font-medium text-base"
                >
                  Download
                </button>
                &bull;
                <button
                  phx-click="view_transcript"
                  phx-value-id={video.id}
                  disabled
                  class="text-gray-100 hover:text-gray-300 p-1 font-medium text-base cursor-not-allowed"
                >
                  View transcript
                </button>
                &bull;
                <button
                  phx-click="delete_video"
                  phx-value-id={video.id}
                  class="text-red-300 hover:text-white p-1 font-medium text-base"
                >
                  Delete
                </button>
              </div>
            </div>
            <div :if={@status[video.id]} class="h-10 pt-1 text-base font-mono">
              <AlgoraWeb.StudioLive.Status.info status={@status[video.id]} />
            </div>
          </div>
        </div>
      </:col>
      <:col :let={{_id, video}} label="Visibility">
        <div class="flex items-center gap-2">
          <Heroicons.globe_alt :if={video.visibility == :public} class="h-6 w-6 text-gray-300" />
          <Heroicons.link :if={video.visibility == :unlisted} class="h-6 w-6 text-gray-300" />
          <div class="text-gray-100 font-medium">
            <%= String.capitalize(to_string(video.visibility)) %>
          </div>
        </div>
      </:col>
      <:col :let={{_id, video}} label="Date">
        <div class="font-medium text-gray-100">
          <%= video.inserted_at |> Calendar.strftime("%b %d, %Y") %>
        </div>
        <div class="text-gray-400">
          <div :if={video.type == :vod}>Uploaded</div>
          <div :if={video.type == :livestream}>Streamed</div>
        </div>
      </:col>
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
      |> stream(:videos, Library.list_studio_videos(channel))
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
    socket =
      socket
      |> assign(:status, socket.assigns.status |> Map.put(video.id, status))
      |> stream_insert(:videos, video)

    socket =
      if video.transmuxed_from_id do
        socket |> redirect(external: url)
      else
        socket
      end

    {:noreply, socket}
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
    videos =
      consume_uploaded_entries(socket, :video, fn %{path: path}, entry ->
        video = Library.init_mp4!(entry, path, socket.assigns.current_user)

        send(self(), {Library, %Library.Events.ProcessingQueued{video: video}})

        %{video_id: video.id}
        |> Workers.HLSTransmuxer.new()
        |> Oban.insert()

        {:ok, video}
      end)

    {:noreply, socket |> stream(:videos, videos, at: 0)}
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
      <div class="text-yellow-400">
        Queued for processing...
      </div>
      """
    end

    def info(%{status: %Library.Events.ProcessingProgressed{}} = assigns) do
      ~H"""
      <div class="text-blue-400">
        Processing your video: <%= @status.stage %>
      </div>
      <div>
        [<%= :erlang.float_to_binary(@status.pct * 100.0, decimals: 0) %>%]
      </div>
      """
    end

    def info(%{status: %Library.Events.ProcessingCompleted{}} = assigns) do
      ~H"""
      <div class="text-green-400">
        Processing completed!
      </div>
      """
    end

    def info(%{status: %Library.Events.ProcessingFailed{}} = assigns) do
      ~H"""
      <div class={
        if(@status.attempt == @status.max_attempts, do: "text-red-400", else: "text-orange-400")
      }>
        <div>
          Processing failed
        </div>
        <div>
          Attempt: <%= @status.attempt %>/<%= @status.max_attempts %>
        </div>
      </div>
      """
    end
  end
end
