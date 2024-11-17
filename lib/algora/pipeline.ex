defmodule Algora.Pipeline do
  use Membrane.Pipeline

  alias Membrane.Time

  alias Algora.{Admin, Library}
  alias Algora.Pipeline.HLS.LLController

  @segment_duration_seconds 6
  @segment_duration Time.seconds(@segment_duration_seconds)
  @partial_segment_duration Time.milliseconds(200)

  @impl true
  def handle_init(_context, socket: socket) do
    spec = [
      #
      child(:src, %Algora.Pipeline.SourceBin{
        socket: socket,
        validator: %Algora.Pipeline.MessageValidator{pid: self()}
      }),

      #
      get_child(:src)
      |> via_out(:audio)
      |> child(:tee_audio, Membrane.Tee.Parallel),

      #
      get_child(:src)
      |> via_out(:video)
      |> child(:tee_video, Membrane.Tee.Parallel)
    ]

    {[spec: spec], %{socket: socket, video: nil, stream_key: nil}}
  end

  @impl true
  def handle_child_notification(
        {:socket_control_needed, _socket, _source} = notification,
        :src,
        _ctx,
        state
      ) do
    send(self(), notification)
    {[], state}
  end

  @impl true
  def handle_child_notification(:end_of_stream, _element, _ctx, %{stream_key: nil} = state), do:
    {[terminate: :normal], state}
  def handle_child_notification(:end_of_stream, _element, _ctx, state) do
    Algora.Library.toggle_streamer_live(state.video, false)

    # List all pipelines
    pipelines = Membrane.Pipeline.list_pipelines()

    # Check if there are any running livestreams
    livestreams_running = Enum.any?(pipelines, fn pid ->
      GenServer.call(pid, :get_video_id) == state.video.id
    end)

    # If no livestreams are running, destroy old machines
    unless livestreams_running do
      # Logic to destroy old machines
      # This is a placeholder, replace with actual logic to destroy old machines
      IO.puts("Destroying old machines...")
    end

    # TODO: close any open connections (e.g. Algora.Restream.WebSocket)

    {[terminate: :normal], state}
  end

  def handle_child_notification({:track_playable, :video}, _element, _ctx, state) do
    {:ok, _ref} = :timer.send_after(@segment_duration_seconds * 1000, self(), :go_live)
    {[], state}
  end

  @impl true
  def handle_child_notification({:stream_validation_error, _phase, _reason}, _element, _ctx, state) do
    {[terminate: :normal], state}
  end

  @impl true
  def handle_child_notification(_notification, _element, _ctx, state) do
    {[], state}
  end

  @impl true
  def handle_info({:socket_control_needed, socket, source} = notification, _ctx, state) do
    case Membrane.RTMP.SourceBin.pass_control(socket, source) do
      :ok ->
        :ok

      {:error, :not_owner} ->
        Process.send_after(self(), notification, 200)
    end

    {[], state}
  end

  def handle_info({:forward_rtmp, url, ref}, _ctx, state) do
    spec = [
      #
      child(ref, %Membrane.RTMP.Sink{rtmp_url: url}),

      #
      get_child(:tee_audio)
      |> via_in(Pad.ref(:audio, 0), toilet_capacity: 10_000)
      |> get_child(ref),

      #
      get_child(:tee_video)
      |> via_in(Pad.ref(:video, 0), toilet_capacity: 10_000)
      |> get_child(ref)
    ]

    {[spec: spec], state}
  end

  def handle_info(:multicast_algora, _ctx, state) do
    user = Algora.Accounts.get_user_by!(handle: "algora")
    destinations = Algora.Accounts.list_active_destinations(user.id)

    for destination <- destinations do
      url =
        URI.new!(destination.rtmp_url)
        |> URI.append_path("/" <> destination.stream_key)
        |> URI.to_string()

      send(self(), {:forward_rtmp, url, String.to_atom("rtmp_sink_#{destination.id}")})
    end

    if url = Algora.Accounts.get_restream_ws_url(user) do
      Task.Supervisor.start_child(
        Algora.TaskSupervisor,
        fn ->
          Algora.Restream.Websocket.start_link(%{
            url: url,
            user: user,
            video: state.video
          })
        end,
        restart: :transient
      )
    end

    {[], state}
  end

  def handle_info(:go_live, _ctx, state) do
    Algora.Library.toggle_streamer_live(state.video, true)
    {[], state}
  end

  @impl true
  def handle_call(:get_video_id, _ctx, state) do
    {[{:reply, state.video.id}], state}
  end

  def handle_call({:validate_stream_key, stream_key}, _ctx, %{ stream_key: nil } = state) do
    if user = Algora.Accounts.get_user_by(stream_key: stream_key) do
      video = Library.init_livestream!()

      dir = Path.join(Admin.tmp_dir(), video.uuid)

      :rpc.multicall(LLController, :start, [video.uuid, dir])

      {:ok, video} =
        Algora.Library.reconcile_livestream(
          %Algora.Library.Video{id: video.id},
          stream_key
        )

      destinations = Algora.Accounts.list_active_destinations(video.user_id)

      for {destination, i} <- Enum.with_index(destinations) do
        url =
          URI.new!(destination.rtmp_url)
          |> URI.append_path("/" <> destination.stream_key)
          |> URI.to_string()

        send(self(), {:forward_rtmp, url, String.to_atom("rtmp_sink_#{i}")})
      end

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

      spec = [
        #
        child(:sink, %Algora.Pipeline.SinkBin{
          video_uuid: video.uuid,
          hls_mode: :muxed_av,
          mode: :live,
          manifest_module: Algora.Pipeline.HLS,
          target_window_duration: :infinity,
          persist?: false,
          storage: %Algora.Pipeline.Storage{video: video, directory: dir}
        }),

        #
        get_child(:tee_audio)
        |> via_in(Pad.ref(:input, :audio),
          options: [
            encoding: :AAC,
            segment_duration: @segment_duration,
            partial_segment_duration: @partial_segment_duration
          ]
        )
        |> get_child(:sink),

        #
        get_child(:tee_video)
        |> via_in(Pad.ref(:input, :video),
          options: [
            encoding: :H264,
            segment_duration: @segment_duration,
            partial_segment_duration: @partial_segment_duration
          ]
        )
        |> get_child(:sink)
      ]

      {
        [reply: {:ok, "success"}, spec: spec],
        %{ state | stream_key: stream_key, video: video }
      }
    else
      {[reply: {:error, "invalid stream key"}, terminate: :normal], state}
    end
  end
  # ReleaseStream message when stream key is set with url
  def handle_call({:validate_stream_key, ""}, _ctx, %{stream_key: key} = state) when is_binary(key), do:
    {[reply: {:ok, "success"}], state}
  # ReleaseStream message when stream key both in url and as stream key
  def handle_call({:validate_stream_key, key}, _ctx, %{stream_key: key} = state), do:
    {[reply: {:ok, "success"}], state}
  # Release Stream message with a stream key differing from the stream key in the url
  def handle_call({:validate_stream_key, _}, _ctx, %{stream_key: key} = state) when is_binary(key), do:
    {[reply: {:error, "stream already setup"}, terminate: :normal], state}

end
