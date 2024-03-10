defmodule AlgoraWeb.SidePanelLive do
  use AlgoraWeb, {:live_view, container: {:div, class: "flex-1"}}
  alias Algora.{Chat, Library}

  on_mount {AlgoraWeb.UserAuth, :current_user}

  def render(assigns) do
    assigns = assigns |> assign(:tabs, [:transcript, :chat])

    ~H"""
    <div class="p-4 bg-gray-800/40 w-[23rem] backdrop-blur-xl rounded-2xl shadow-inner shadow-white/[10%] border border-white/[15%]">
      <div>
        <ul class="pb-2 flex items-center justify-center gap-2 mx-auto text-gray-400">
          <li :for={{tab, i} <- Enum.with_index(@tabs)}>
            <button
              id={"side-panel-tab-#{tab}"}
              class={[
                "text-xs font-medium uppercase tracking-wide",
                i == 0 && "active-tab text-white pointer-events-none"
              ]}
              phx-click={
                set_active_tab("#side-panel-tab-#{tab}")
                |> set_active_content("#side-panel-content-#{tab}")
              }
            >
              <%= tab %>
            </button>
          </li>
        </ul>
      </div>

      <div>
        <div
          :for={{tab, i} <- Enum.with_index(@tabs)}
          id={"side-panel-content-#{tab}"}
          class={["side-panel-content", i != 0 && "hidden"]}
        >
          <div
            :if={tab == :transcript}
            id="transcript-subtitles"
            class="text-sm break-words flex-1 overflow-y-auto h-[calc(100vh-11rem)]"
          >
            <div :for={subtitle <- @subtitles} id={"subtitle-#{subtitle.id}"}>
              <span class="font-semibold text-indigo-400">
                <%= Library.to_hhmmss(subtitle.start) %>
              </span>
              <span class="font-medium text-gray-100">
                <%= subtitle.body %>
              </span>
            </div>
          </div>

          <div :if={tab == :chat}>
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

  defp set_active_content(js \\ %JS{}, to) do
    js
    |> JS.hide(to: ".side-panel-content")
    |> JS.show(to: to)
  end

  defp set_active_tab(js \\ %JS{}, tab) do
    js
    |> JS.remove_class("active-tab text-white pointer-events-none",
      to: "#video-side-panel .active-tab"
    )
    |> JS.add_class("active-tab text-white pointer-events-none", to: tab)
  end

  defp system_message?(%Chat.Message{} = message) do
    message.sender_handle == "algora"
  end
end
