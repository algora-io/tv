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
    <form id="upload-form" phx-submit="save" phx-change="validate">
      <.live_file_input upload={@uploads.video} />
      <button type="submit">Upload</button>
    </form>
    <%!-- lib/my_app_web/live/upload_live.html.heex --%>

    <%!-- use phx-drop-target with the upload ref to enable file drag and drop --%>
    <section phx-drop-target={@uploads.video.ref}>
      <%!-- render each video entry --%>
      <%= for entry <- @uploads.video.entries do %>
        <article class="upload-entry">
          <div><%= entry.client_name %></div>

          <%!-- entry.progress will update automatically for in-flight entries --%>
          <progress value={entry.progress} max="100"><%= entry.progress %>%</progress>

          <%!-- a regular click event whose handler will invoke Phoenix.LiveView.cancel_upload/3 --%>
          <button
            type="button"
            phx-click="cancel-upload"
            phx-value-ref={entry.ref}
            aria-label="cancel"
          >
            &times;
          </button>

          <%!-- Phoenix.Component.upload_errors/2 returns a list of error atoms --%>
          <%= for err <- upload_errors(@uploads.video, entry) do %>
            <p class="alert alert-danger"><%= error_to_string(err) %></p>
          <% end %>
        </article>
      <% end %>

      <%!-- Phoenix.Component.upload_errors/1 returns a list of error atoms --%>
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

  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("save", _params, socket) do
    uploaded_videos =
      consume_uploaded_entries(socket, :video, fn %{path: path}, _entry ->
        dst_path = Path.join([:code.priv_dir(:algora), "static", "uploads", Path.basename(path)])
        File.cp!(path, dst_path)
        {:ok, ~p"/uploads/#{Path.basename(dst_path)}"}
      end)

    {:noreply, update(socket, :uploaded_videos, &(&1 ++ uploaded_videos))}
  end

  defp apply_action(socket, :show, _params) do
    socket |> assign(:page_title, "Studio")
  end

  defp error_to_string(:too_large), do: "Too large"
  defp error_to_string(:not_accepted), do: "You have selected an unacceptable file type"
  defp error_to_string(:too_many_files), do: "You have selected too many files"

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
