defmodule AlgoraWeb.ChatPopoutLive do
  use AlgoraWeb, :live_view
  require Logger

  import AlgoraWeb.Components.Avatar

  alias Algora.{Accounts, Library, Chat}
  alias AlgoraWeb.RTMPDestinationIconComponent

  def render(assigns) do
    ~H"""
    <aside id="side-panel" class="w-full h-screen rounded overflow-hidden">
      <div class="h-full flex flex-col bg-gray-800/40 overflow-hidden shadow-inner shadow-white/[10%] border border-white/[15%]">
        <div id="side-panel-content-chat" class="side-panel-content flex-grow">
          <div>
            <div
              id="chat-messages"
              phx-hook="Chat"
              phx-update="stream"
              class="text-sm break-words flex-1 scrollbar-thin overflow-y-auto inset-0 h-[calc(100vh-80px)] py-4 space-y-2.5"
            >
              <div
                :for={{id, message} <- @streams.messages}
                id={id}
                class="px-4 flex items-start gap-2"
              >
                <div class="relative h-6 w-6 shrink-0">
                  <.user_avatar
                    src={message.sender_avatar_url}
                    alt={message.sender_handle}
                    class="rounded-full h-6 w-6 [&_.fallback]:bg-gray-700 [&_.fallback]:text-xs"
                  />
                  <RTMPDestinationIconComponent.icon
                    :if={message.platform != "algora"}
                    class="absolute -right-1 -bottom-1 flex w-4 h-4 shrink-0 bg-[#110f2c]"
                    icon={String.to_atom(message.platform)}
                  />
                </div>
                <div>
                  <span class={"font-semibold #{if(system_message?(message), do: "text-indigo-400", else: "text-emerald-400")}"}>
                    <%= message.sender_name %>
                  </span>
                  <span class="font-medium text-gray-100">
                    <%= message.body %>
                  </span>
                </div>
              </div>
            </div>
          </div>
        </div>
        <div class="px-4 py-2">
          <.simple_form
            :if={@current_user}
            for={@chat_form}
            phx-submit="send"
            phx-change="validate"
          >
            <div class="flex flex-col items-center justify-between gap-2">
              <div class="w-full">
                <.input
                  field={@chat_form[:body]}
                  placeholder="Send a message"
                  autocomplete="off"
                />
              </div>
            </div>
          </.simple_form>
          <div :if={!@current_user} class="text-center text-gray-400 py-2">
            Please sign in to chat
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
      Chat.subscribe_to_room(video)
    end

    {:ok,
     socket
     |> assign(channel: channel, video: video)
     |> assign(chat_form: to_form(Chat.change_message(%Chat.Message{})))
     |> stream(:messages, Chat.list_messages(video))}
  end

  def handle_event("validate", %{"message" => %{"body" => ""}}, socket), do: {:noreply, socket}

  def handle_event("validate", %{"message" => params}, socket) do
    form =
      %Chat.Message{}
      |> Chat.change_message(params)
      |> Map.put(:action, :insert)
      |> to_form()

    {:noreply, assign(socket, chat_form: form)}
  end

  def handle_event("send", %{"message" => %{"body" => ""}}, socket), do: {:noreply, socket}

  def handle_event("send", %{"message" => params}, socket) do
    %{current_user: current_user, video: video} = socket.assigns

    case Chat.create_message(current_user, video, params) do
      {:ok, message} ->
        message = Chat.get_message!(message.id)
        Chat.broadcast_message_sent!(message)
        {:noreply, assign(socket, chat_form: to_form(Chat.change_message(%Chat.Message{})))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, chat_form: to_form(changeset))}
    end
  end

  def handle_info({Chat, %Chat.Events.MessageDeleted{message: message}}, socket) do
    {:noreply, stream_delete(socket, :messages, message)}
  end

  def handle_info({Chat, %Chat.Events.MessageSent{message: message}}, socket) do
    {:noreply, stream_insert(socket, :messages, message)}
  end

  defp system_message?(%Chat.Message{} = message) do
    message.sender_handle == "algora"
  end
end
