defmodule Algora.Pipeline.MessageValidator do
  defstruct [:video_id, :pid]
end

defimpl Membrane.RTMP.MessageValidator, for: Algora.Pipeline.MessageValidator do
  @impl true
  def validate_connect(impl, message) do
    {:ok, video} =
      Algora.Library.reconcile_livestream(
        %Algora.Library.Video{id: impl.video_id},
        message.app
      )

    destinations = Algora.Accounts.list_active_destinations(video.user_id)

    for {destination, i} <- Enum.with_index(destinations) do
      url =
        URI.new!(destination.rtmp_url)
        |> URI.append_path("/" <> destination.stream_key)
        |> URI.to_string()

      send(impl.pid, {:forward_rtmp, url, String.to_atom("rtmp_sink_#{i}")})
    end

    user = Algora.Accounts.get_user!(video.user_id)

    if url = Algora.Accounts.get_restream_ws_url(user) do
      Task.Supervisor.start_child(
        Algora.TaskSupervisor,
        fn -> Algora.Restream.Websocket.start_link(%{url: url, user: user, video: video}) end,
        restart: :transient
      )
    end

    youtube_handle =
      case user.id do
        307 -> "@heyandras"
        9 -> "@dragonroyale"
        _ -> nil
      end

    if youtube_handle do
      DynamicSupervisor.start_child(
        Algora.Youtube.Chat.Supervisor,
        {Algora.Youtube.Chat.Fetcher, %{video: video, youtube_handle: youtube_handle}}
      )
    end

    {:ok, "connect success"}
  end

  @impl true
  def validate_release_stream(_impl, _message) do
    {:ok, "release stream success"}
  end

  @impl true
  def validate_publish(_impl, _message) do
    {:ok, "validate publish success"}
  end

  @impl true
  def validate_set_data_frame(_impl, _message) do
    {:ok, "set data frame success"}
  end
end
