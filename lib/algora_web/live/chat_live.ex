defmodule AlgoraWeb.ChatLive do
  use AlgoraWeb, :live_view
  require Logger

  import AlgoraWeb.Components.Avatar

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
        <div class="relative h-[400px] w-[400px]">
          <div
            id="side-panel-content-chat"
            class="side-panel-content w-full h-full absolute transition-opacity duration-1000 opacity-100"
            data-selected={set_active_content("#side-panel-content-chat")}
          >
            <div
              id="chat-messages"
              phx-hook="Chat"
              phx-update="stream"
              class="text-sm break-words flex-1 scrollbar-thin overflow-y-auto inset-0 h-[400px] py-4 space-y-2.5"
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
          <div
            id="side-panel-content-logos"
            class="side-panel-content w-full h-full absolute transition-opacity duration-1000 opacity-0"
            data-selected={set_active_content("#side-panel-content-logos")}
          >
            <div class="bg-black px-4 py-4 rounded text-center">
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
          </div>
        </div>
      </div>
    </aside>
    """
  end

  def mount(%{"channel_handle" => channel_handle} = params, _session, socket) do
    user = Accounts.get_user_by!(handle: channel_handle)
    channel = Library.get_channel!(user)

    video =
      case params["video_id"] do
        nil -> Library.get_latest_video(user)
        id -> Library.get_video!(id)
      end

    messages =
      case video do
        nil -> []
        video -> Chat.list_messages(video)
      end

    if connected?(socket) do
      Library.subscribe_to_livestreams()
      Library.subscribe_to_channel(channel)
      if video, do: Chat.subscribe_to_room(video)
    end

    {:ok,
     socket
     |> assign(:channel, channel)
     |> assign(:video, video)
     |> stream(:messages, messages)}
  end

  def handle_params(params, _url, socket) do
    LayoutComponent.hide_modal()
    {:noreply, socket |> apply_action(socket.assigns.live_action, params)}
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

  def handle_info(
        {Library, %Library.Events.LivestreamStarted{video: video}},
        socket
      ) do
    if video.user_id != socket.assigns.channel.user_id do
      {:noreply, socket}
    else
      Chat.unsubscribe_to_room(socket.assigns.video)
      Chat.subscribe_to_room(video)
      {:noreply, socket |> assign(:video, video)}
    end
  end

  def handle_info({Library, %Library.Events.OverlaySetToLogos{}}, socket) do
    {:noreply, socket |> push_overlay("logos")}
  end

  def handle_info({Library, %Library.Events.OverlaySetToChat{}}, socket) do
    {:noreply, socket |> push_overlay("chat")}
  end

  def handle_info(_arg, socket), do: {:noreply, socket}

  defp push_overlay(socket, name) do
    socket |> push_event("js-exec", %{to: "#side-panel-content-#{name}", attr: "data-selected"})
  end

  defp set_active_content(js \\ %JS{}, to) do
    js
    |> JS.remove_class("opacity-100", to: ".side-panel-content")
    |> JS.add_class("opacity-0", to: ".side-panel-content")
    |> JS.remove_class("opacity-0", to: to)
    |> JS.add_class("opacity-100", to: to)
  end

  defp system_message?(%Chat.Message{} = message) do
    message.sender_handle == "algora"
  end

  defp apply_action(socket, :show, params) do
    channel_name = socket.assigns.channel.name || params["channel_handle"]

    case socket.assigns.video do
      nil ->
        socket
        |> assign(:page_title, channel_name)
        |> assign(:page_description, "Watch #{channel_name} on Algora TV")

      video ->
        socket
        |> assign(:page_title, channel_name)
        |> assign(:page_description, video.title)
        |> assign(:page_image, Library.get_og_image_url(video))
    end
  end
end
