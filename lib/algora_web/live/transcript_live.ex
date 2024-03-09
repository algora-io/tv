defmodule AlgoraWeb.TranscriptLive do
  alias Algora.Library
  alias Algora.Library.Video
  use AlgoraWeb, {:live_view, container: {:div, []}}

  on_mount {AlgoraWeb.UserAuth, :current_user}

  def render(assigns) do
    ~H"""
    <div>
      <div
        id="transcript-subtitles"
        class="text-sm break-words flex-1 overflow-y-auto h-[calc(100vh-11rem)]"
      >
        <div :for={subtitle <- @subtitles} id={"subtitle-#{subtitle.id}"}>
          <span class="font-semibold text-indigo-400">
            <%= Library.to_hhmmss(subtitle.start) %>:
          </span>
          <span class="font-medium text-gray-100">
            <%= subtitle.body %>
          </span>
        </div>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, socket, temporary_assigns: [subtitles: []]}
  end

  def handle_event("join", %{"video_id" => video_id}, socket) do
    socket =
      socket
      |> assign(subtitles: Library.list_subtitles(%Video{id: video_id}))
      |> push_event(:show_transcript, %{id: video_id})

    {:noreply, socket}
  end
end
