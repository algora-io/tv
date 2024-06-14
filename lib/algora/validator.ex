defmodule Algora.MessageValidator do
  defstruct [:video_id, :pid]
end

defimpl Membrane.RTMP.MessageValidator, for: Algora.MessageValidator do
  @impl true
  def validate_connect(impl, message) do
    dbg({:validate_connect, {impl, message}})

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

    # send(impl.pid, {:forward_rtmp, nil, String.to_atom("rtmp_sink_algora")})

    user = Algora.Accounts.get_user!(video.user_id)

    if url = Algora.Accounts.get_restream_ws_url(user) do
      Task.Supervisor.start_child(
        Algora.TaskSupervisor,
        fn -> Algora.Restream.Websocket.start_link(%{url: url, video: video}) end,
        restart: :transient
      )
    end

    {:ok, "connect success"}
  end

  @impl true
  def validate_release_stream(impl, message) do
    dbg({:validate_release_stream, {impl, message}})
    {:ok, "release stream success"}
  end

  @impl true
  def validate_publish(impl, message) do
    dbg({:validate_publish, {impl, message}})
    {:ok, "validate publish success"}
  end

  @impl true
  def validate_set_data_frame(impl, message) do
    dbg({:validate_set_data_frame, {impl, message}})
    {:ok, "set data frame success"}
  end
end
