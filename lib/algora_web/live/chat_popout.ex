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
          <div :if={!@current_user} class="lg:pt-2 lg:pb-0 py-4">
            <a
              href={Algora.Github.authorize_url()}
              class="w-full flex items-center gap-4 justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-purple-600 hover:bg-purple-500 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-purple-400"
            >
              <svg
                width="98"
                height="96"
                xmlns="http://www.w3.org/2000/svg"
                class="h-6 w-6 -ml-2"
                viewBox="0 0 98 96"
              >
                <path
                  fill-rule="evenodd"
                  clip-rule="evenodd"
                  d="M48.854 0C21.839 0 0 22 0 49.217c0 21.756 13.993 40.172 33.405 46.69 2.427.49 3.316-1.059 3.316-2.362 0-1.141-.08-5.052-.08-9.127-13.59 2.934-16.42-5.867-16.42-5.867-2.184-5.704-5.42-7.17-5.42-7.17-4.448-3.015.324-3.015.324-3.015 4.934.326 7.523 5.052 7.523 5.052 4.367 7.496 11.404 5.378 14.235 4.074.404-3.178 1.699-5.378 3.074-6.6-10.839-1.141-22.243-5.378-22.243-24.283 0-5.378 1.94-9.778 5.014-13.2-.485-1.222-2.184-6.275.486-13.038 0 0 4.125-1.304 13.426 5.052a46.97 46.97 0 0 1 12.214-1.63c4.125 0 8.33.571 12.213 1.63 9.302-6.356 13.427-5.052 13.427-5.052 2.67 6.763.97 11.816.485 13.038 3.155 3.422 5.015 7.822 5.015 13.2 0 18.905-11.404 23.06-22.324 24.283 1.78 1.548 3.316 4.481 3.316 9.126 0 6.6-.08 11.897-.08 13.526 0 1.304.89 2.853 3.316 2.364 19.412-6.52 33.405-24.935 33.405-46.691C97.707 22 75.788 0 48.854 0z"
                  fill="#fff"
                />
              </svg>
              <span>Sign in to chat</span>
            </a>
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
