defmodule Algora.Pipeline do
  alias Membrane.Time
  alias Algora.Library

  use Membrane.Pipeline

  @segment_duration Time.seconds(6)
  @partial_segment_duration Time.milliseconds(1_100)

  @impl true
  def handle_init(_context, socket: socket) do
    video = Library.init_livestream!()

    spec = [
      #
      child(:src, %Algora.SourceBin{
        socket: socket,
        validator: %Algora.MessageValidator{video_id: video.id, pid: self()}
      }),

      #
      child(:sink, %Membrane.HTTPAdaptiveStream.SinkBin{
        hls_mode: :muxed_av,
        mode: :live,
        manifest_module: Membrane.HTTPAdaptiveStream.HLS,
        target_window_duration: :infinity,
        persist?: false,
        storage: %Algora.Storage{video: video, pid: self()}
      }),

      #
      get_child(:src)
      |> via_out(:audio)
      |> child(:tee_audio, Membrane.Tee.Master),

      #
      get_child(:src)
      |> via_out(:video)
      |> child(:tee_video, Membrane.Tee.Master),

      #
      get_child(:tee_audio)
      |> via_out(:master)
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
      |> via_out(:master)
      |> via_in(Pad.ref(:input, :video),
        options: [
          encoding: :H264,
          segment_duration: @segment_duration,
          partial_segment_duration: @partial_segment_duration
        ]
      )
      |> get_child(:sink)
    ]

    {[spec: spec], %{socket: socket, video: video, hls_msn: 0, hls_part: -1}}
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
  def handle_child_notification(:end_of_stream, _element, _ctx, state) do
    Algora.Library.toggle_streamer_live(state.video, false)

    # TODO: gracefully terminate open connections (e.g. RTMP, WS)
    {[], state}
  end

  def handle_child_notification({:track_playable, :video}, _element, _ctx, state) do
    Algora.Library.toggle_streamer_live(state.video, true)
    {[], state}
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
      |> via_out(:copy)
      |> via_in(Pad.ref(:audio, 0), toilet_capacity: 10_000)
      |> get_child(ref),

      #
      get_child(:tee_video)
      |> via_out(:copy)
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
        fn -> Algora.Restream.Websocket.start_link(%{url: url, video: state.video}) end,
        restart: :transient
      )
    end

    {[], state}
  end

  def handle_info({:hls_msn, hls_msn}, _ctx, state) do
    state = %{state | hls_msn: hls_msn + 1}
    dbg(Map.take(state, [:hls_msn, :hls_part]))
    {[], state}
  end

  def handle_info({:hls_part, hls_part}, _ctx, state) do
    state = %{state | hls_part: hls_part}
    dbg(Map.take(state, [:hls_msn, :hls_part]))
    {[], state}
  end

  @impl true
  def handle_call(:get_video_id, _ctx, state) do
    {[{:reply, state.video.id}], state}
  end

  def handle_call(:get_video_uuid, _ctx, state) do
    {[{:reply, state.video.uuid}], state}
  end

  def handle_call(:get_hls_params, _ctx, state) do
    {[{:reply, %{hls_msn: state.hls_msn, hls_part: state.hls_part}}], state}
  end
end
