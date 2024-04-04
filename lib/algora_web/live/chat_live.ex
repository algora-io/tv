defmodule AlgoraWeb.ChatLive do
  use AlgoraWeb, :live_view
  require Logger

  alias Algora.{Accounts, Library, Storage, Chat}
  alias AlgoraWeb.{LayoutComponent, Presence}

  def render(assigns) do
    assigns = assigns |> assign(tabs: [:chat])

    ~H"""
    <aside id="side-panel" class="hidden lg:w-[24rem] lg:flex fixed top-[64px] right-0 w-0 pr-4">
      <div class="p-4">
        <div>
          <div
            :for={{tab, i} <- Enum.with_index(@tabs)}
            id={"side-panel-content-#{tab}"}
            class={["side-panel-content", i != 0 && "hidden"]}
          >
            <div>
              <div
                id="chat-messages"
                phx-update="ignore"
                class="text-sm break-words flex-1 overflow-y-auto inset-0 h-[400px] w-[400px] fixed overflow-hidden"
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
            </div>
          </div>
        </div>
      </div>
    </aside>
    """
  end

  def mount(%{"channel_handle" => channel_handle, "video_id" => video_id}, _session, socket) do
    channel =
      Accounts.get_user_by!(handle: channel_handle)
      |> Library.get_channel!()

    if connected?(socket) do
      Library.subscribe_to_livestreams()
      Library.subscribe_to_channel(channel)

      Presence.subscribe(channel_handle)
    end

    videos = Library.list_channel_videos(channel, 50)

    video = Library.get_video!(video_id)

    subtitles = Library.list_subtitles(%Library.Video{id: video_id})

    data = %{}

    {:ok, encoded_subtitles} =
      subtitles
      |> Enum.map(&%{id: &1.id, start: &1.start, end: &1.end, body: &1.body})
      |> Jason.encode(pretty: true)

    types = %{subtitles: :string}
    params = %{subtitles: encoded_subtitles}

    changeset =
      {data, types}
      |> Ecto.Changeset.cast(params, Map.keys(types))

    socket =
      socket
      |> assign(
        channel: channel,
        videos_count: Enum.count(videos),
        video: video,
        subtitles: subtitles,
        messages: Chat.list_messages(video)
      )
      |> assign_form(changeset)
      |> stream(:videos, videos)
      |> stream(:presences, Presence.list_online_users(channel_handle))

    if connected?(socket), do: send(self(), {:play, video})

    {:ok, socket}
  end

  def handle_params(params, _url, socket) do
    LayoutComponent.hide_modal()
    {:noreply, socket |> apply_action(socket.assigns.live_action, params)}
  end

  def handle_info({:play, video}, socket) do
    socket = socket |> push_event("join_chat", %{id: video.id})
    {:noreply, socket}
  end

  def handle_info({Presence, {:join, presence}}, socket) do
    {:noreply, stream_insert(socket, :presences, presence)}
  end

  def handle_info({Presence, {:leave, presence}}, socket) do
    if presence.metas == [] do
      {:noreply, stream_delete(socket, :presences, presence)}
    else
      {:noreply, stream_insert(socket, :presences, presence)}
    end
  end

  def handle_info(
        {Storage, %Library.Events.ThumbnailsGenerated{video: video}},
        socket
      ) do
    {:noreply,
     if video.user_id == socket.assigns.channel.user_id do
       socket
       |> stream_insert(:videos, video, at: 0)
     else
       socket
     end}
  end

  def handle_info(
        {Library, %Library.Events.LivestreamStarted{video: video}},
        socket
      ) do
    %{channel: channel} = socket.assigns

    {:noreply,
     if video.user_id == channel.user_id do
       socket
       |> assign(channel: %{channel | is_live: true})
       |> stream_insert(:videos, video, at: 0)
     else
       socket
     end}
  end

  def handle_info(
        {Library, %Library.Events.LivestreamEnded{video: video}},
        socket
      ) do
    %{channel: channel} = socket.assigns

    {:noreply,
     if video.user_id == channel.user_id do
       socket
       |> assign(channel: %{channel | is_live: false})
       |> stream_insert(:videos, video)
     else
       socket
     end}
  end

  def handle_info({Library, _}, socket), do: {:noreply, socket}

  defp system_message?(%Chat.Message{} = message) do
    message.sender_handle == "algora"
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset, as: :data))
  end

  defp apply_action(socket, :show, params) do
    socket
    |> assign(:page_title, socket.assigns.channel.name || params["channel_handle"])
    |> assign(:channel_handle, socket.assigns.channel.handle)
    |> assign(:channel_name, socket.assigns.channel.name)
    |> assign(:channel_tagline, socket.assigns.channel.tagline)
    |> assign(:video, nil)
  end
end
