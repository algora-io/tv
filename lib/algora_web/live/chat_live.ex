defmodule AlgoraWeb.ChatLive do
  use AlgoraWeb, :live_view
  require Logger

  alias Algora.{Accounts, Library, Chat}
  alias AlgoraWeb.{LayoutComponent, RTMPDestinationIconComponent}

  def render(assigns) do
    ~H"""
    <aside id="side-panel" class="w-[400px] rounded ring-1 ring-purple-300 m-1 overflow-hidden">
      <div>
        <div :if={@channel.solving_challenge} class="bg-black px-4 py-4 rounded text-center">
          <div class="font-medium text-base">
            <.link
              href="https://console.algora.io/challenges/tsperf"
              class="font-semibold text-green-300 hover:underline"
            >
              Solving the $15,000 TSPerf Challenge
            </.link>
          </div>
          <div class="pt-1.5 font-medium text-sm">
            sponsored by
          </div>
          <div class="pt-2.5 mx-auto grid max-w-6xl gap-4 text-center grid-cols-3">
            <a
              target="_blank"
              rel="noopener"
              class="flex h-full flex-1 flex-col items-center text-white no-underline hover:no-underline"
              href="https://unkey.com"
            >
              <img
                src="https://console.algora.io/banners/unkey.png"
                alt="Unkey"
                class="-mt-1 h-8 w-auto saturate-0"
              />
            </a>
            <a
              target="_blank"
              rel="noopener"
              class="flex h-full flex-1 flex-col items-center text-white no-underline hover:no-underline"
              href="https://scalar.com"
            >
              <img
                src="https://console.algora.io/banners/scalar.png"
                alt="Scalar"
                class="h-6 w-auto saturate-0"
              />
            </a>
            <a
              target="_blank"
              rel="noopener"
              class="flex h-full flex-1 flex-col items-center text-white no-underline hover:no-underline"
              href="https://tigrisdata.com"
            >
              <img
                src="https://assets-global.website-files.com/657988158c7fb30f4d9ef37b/657990b61fd3a5d674cf2298_tigris-logo.svg"
                alt="Tigris"
                class="mt-1 h-6 w-auto saturate-0"
              />
            </a>
          </div>
        </div>
        <div>
          <div id="side-panel-content-chat" class="side-panel-content">
            <div>
              <div
                id="chat-messages"
                phx-hook="Chat"
                phx-update="stream"
                class="text-sm break-words flex-1 scrollbar-thin overflow-y-auto inset-0 h-[400px] py-4"
              >
                <div :for={{id, message} <- @streams.messages} id={id} class="px-4">
                  <RTMPDestinationIconComponent.icon
                    :if={message.platform != "algora"}
                    class="inline-flex w-5 h-5 shrink-0 mr-0.5"
                    icon={String.to_atom(message.platform)}
                  />
                  <span class={"font-semibold #{if(system_message?(message), do: "text-emerald-400", else: "text-indigo-400")}"}>
                    <%= message.sender_handle %>:
                  </span>
                  <span class="font-medium text-gray-100">
                    <%= message.body %>
                  </span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </aside>
    """
  end

  def mount(%{"channel_handle" => channel_handle, "video_id" => video_id}, _session, socket) do
    channel = Accounts.get_user_by!(handle: channel_handle) |> Library.get_channel!()
    video = Library.get_video!(video_id)

    if connected?(socket) do
      Library.subscribe_to_livestreams()
      Library.subscribe_to_channel(channel)
      Chat.subscribe_to_room(video)
    end

    socket =
      socket
      |> assign(:channel, channel)
      |> assign(:video, video)
      |> stream(:messages, Chat.list_messages(video))

    if connected?(socket), do: send(self(), {:join_chat, video})

    {:ok, socket}
  end

  def handle_params(params, _url, socket) do
    LayoutComponent.hide_modal()
    {:noreply, socket |> apply_action(socket.assigns.live_action, params)}
  end

  def handle_info({:join_chat, video}, socket) do
    {:noreply, socket |> push_event("join_chat", %{id: video.id})}
  end

  def handle_info(
        {Chat, %Chat.Events.MessageDeleted{message: message}},
        socket
      ) do
    {:noreply, socket |> stream_delete(:messages, message)}
  end

  def handle_info(
        {Chat, %Chat.Events.MessageSent{message: message}},
        socket
      ) do
    {:noreply, socket |> stream_insert(:messages, message)}
  end

  def handle_info(_arg, socket), do: {:noreply, socket}

  defp system_message?(%Chat.Message{} = message) do
    message.sender_handle == "algora"
  end

  defp apply_action(socket, :show, params) do
    socket
    |> assign(:page_title, socket.assigns.channel.name || params["channel_handle"])
    |> assign(:page_description, socket.assigns.video.title)
    |> assign(:page_image, Library.get_og_image_url(socket.assigns.video))
  end
end
