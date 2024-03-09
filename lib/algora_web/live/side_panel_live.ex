defmodule AlgoraWeb.SidePanelLive do
  use AlgoraWeb, {:live_view, container: {:div, []}}
  alias Algora.{Chat, Library}

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

        <div id="side-panel-content-chat" class="side-panel-content hidden">
          <div
            id="chat-messages"
            class="text-sm break-words flex-1 overflow-y-auto h-[calc(100vh-11rem)]"
          >
            <div :for={message <- @messages} id={"message-#{message.id}"}>
              <span class={"font-semibold #{if(system_message?(message), do: "text-emerald-400", else: "text-indigo-400")}"}>
                <%= message.sender_handle %>:
              </span>
              <span class="font-medium text-gray-100">
                <%= message.body %>
              </span>
            </div>
          </div>
          <input
            :if={@current_user}
            id="chat-input"
            placeholder="Send a message"
            disabled={@current_user == nil}
            class="mt-2 bg-gray-950 h-[30px] text-white focus:outline-none focus:ring-purple-400 block w-full min-w-0 rounded-md sm:text-sm ring-1 ring-gray-600 px-2"
          />
          <a
            :if={!@current_user}
            href={Algora.Github.authorize_url()}
            class="mt-2 w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-purple-600 hover:bg-purple-500 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-purple-400"
          >
            Sign in to chat
          </a>
        </div>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, socket, temporary_assigns: [subtitles: [], messages: []]}
  end

  def handle_event("show", %{"video_id" => video_id}, socket) do
    socket =
      socket
      |> assign(subtitles: Library.list_subtitles(%Library.Video{id: video_id}))
      |> assign(messages: Chat.list_messages(%Library.Video{id: video_id}))
      |> push_event("join_chat", %{id: video_id})

    {:noreply, socket}
  end

  # def handle_event("set_video_tab", %{"tab" => tab}, socket) do
  #   {:noreply, socket}
  # end

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

  defp system_message?(%Chat.Message{} = message) do
    message.sender_handle == "algora"
  end
end
