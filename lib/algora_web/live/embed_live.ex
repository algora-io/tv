defmodule AlgoraWeb.EmbedLive do
  use AlgoraWeb, :live_view
  require Logger

  alias Algora.Pipeline.Storage
  alias Algora.{Accounts, Library, Chat}
  alias AlgoraWeb.{LayoutComponent, Presence, PlayerComponent}

  def render(assigns) do
    ~H"""
    <div class="w-full" id="embed-player-container" phx-update="ignore">
      <.live_component module={PlayerComponent} id="embed-player" />
    </div>
    """
  end

  def mount(%{"channel_handle" => channel_handle, "video_id" => video_id}, _session, socket) do
    channel =
      Accounts.get_user_by!(handle: channel_handle)
      |> Library.get_channel!()

    videos = Library.list_channel_videos(channel, 50)

    video = Library.get_video!(video_id)

    if connected?(socket) do
      Library.subscribe_to_livestreams()
      Library.subscribe_to_channel(channel)

      Presence.subscribe(channel_handle)

      send_update(PlayerComponent, %{
        id: "embed-player",
        video: video,
        current_user: nil
      })
    end

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

    {:ok, socket}
  end

  def handle_params(params, _url, socket) do
    LayoutComponent.hide_modal()
    {:noreply, socket |> apply_action(socket.assigns.live_action, params)}
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

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset, as: :data))
  end

  defp apply_action(socket, :show, params) do
    socket
    |> assign(:page_title, socket.assigns.channel.name || params["channel_handle"])
    |> assign(:page_description, socket.assigns.video.title)
    |> assign(:page_image, Library.get_og_image_url(socket.assigns.video))
  end
end
