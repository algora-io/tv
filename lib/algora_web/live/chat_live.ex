defmodule AlgoraWeb.ChatLive do
  alias Algora.Chat.Message
  alias Algora.{Library, Chat}
  alias Algora.Library.Video
  use AlgoraWeb, {:live_view, container: {:div, []}}

  on_mount {AlgoraWeb.UserAuth, :current_user}

  defp system_message?(%Message{} = message) do
    message.sender_handle == "algora"
  end

  def render(assigns) do
    ~H"""
    <aside
      id="chat-box"
      class="z-50 absolute top-0 right-0 lg:flex w-0 flex-col bg-gray-950 ring-1 ring-gray-800"
    >
      <div class="p-4">
        <div class="pb-2 text-center text-gray-400 text-xs font-medium uppercase tracking-wide">
          Stream chat
        </div>
        <div id="chat-messages" class="break-all flex-1 overflow-y-auto h-[calc(100vh-5.75rem)]">
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
    </aside>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, socket, layout: false, temporary_assigns: [messages: []]}
  end

  def handle_info({Library, _}, socket), do: {:noreply, socket}

  def handle_event("join", %{"video_id" => video_id}, socket) do
    video = Library.get_video!(video_id)

    socket =
      socket
      |> assign(messages: Chat.list_messages(%Video{id: video.id}))
      |> push_event("join_chat", %{id: video.id, type: video.type})

    {:noreply, socket}
  end
end
