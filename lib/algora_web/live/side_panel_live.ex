defmodule AlgoraWeb.SidePanelLive do
  use AlgoraWeb, {:live_view, container: {:div, []}}

  on_mount {AlgoraWeb.UserAuth, :current_user}

  def render(assigns) do
    ~H"""
    <div class="p-4 bg-gray-800/40 backdrop-blur-xl rounded-2xl shadow-inner shadow-white/[10%] border border-white/[15%]">
      <div>
        <ul class="pb-2 flex items-center justify-center gap-2 mx-auto text-gray-400">
          <li>
            <button
              id="side-panel-tab-transcript"
              class="active-tab text-white text-xs font-medium uppercase tracking-wide"
              phx-click={
                set_active_tab("#side-panel-tab-transcript")
                |> set_active_content("#side-panel-content-transcript")
              }
            >
              Transcript
            </button>
          </li>
          <li>
            <button
              id="side-panel-tab-chat"
              class="active-tab text-xs font-medium uppercase tracking-wide"
              phx-click={
                set_active_tab("#side-panel-tab-chat")
                |> set_active_content("#side-panel-content-chat")
              }
            >
              Chat
            </button>
          </li>
        </ul>
      </div>

      <div>
        <div id="side-panel-content-transcript" class="side-panel-content">
          <%= live_render(@socket, AlgoraWeb.TranscriptLive, id: "transcript", session: %{}) %>
        </div>

        <div id="side-panel-content-chat" class="side-panel-content hidden">
          <%= live_render(@socket, AlgoraWeb.ChatLive, id: "chat", session: %{}) %>
        </div>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def handle_event("set_video_tab", %{"tab" => tab}, socket) do
    {:noreply, socket}
  end

  defp set_active_content(js \\ %JS{}, to) do
    js
    |> JS.hide(to: ".side-panel-content")
    |> JS.show(to: to)
  end

  defp set_active_tab(js \\ %JS{}, tab) do
    js
    |> JS.remove_class("active-tab text-white", to: "#video-side-panel.active-tab")
    |> JS.add_class("active-tab text-white", to: tab)
  end
end
