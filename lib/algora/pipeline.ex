defmodule Algora.Pipeline do
  alias Algora.Library
  use Membrane.Pipeline

  @impl true
  def handle_init(_context, socket: socket) do
    video = Library.init_livestream!()

    spec = [
      #
      child(:src, %Membrane.RTMP.SourceBin{
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
        storage: %Algora.Storage{video: video}
      }),

      #
      get_child(:src)
      |> via_out(:audio)
      |> child(:tee_audio, Algora.Tee),

      #
      get_child(:src)
      |> via_out(:video)
      |> child(:tee_video, Algora.Tee),

      #
      get_child(:tee_audio)
      |> via_out(:master)
      |> via_in(Pad.ref(:input, :audio),
        options: [encoding: :AAC, segment_duration: Membrane.Time.seconds(2)]
      )
      |> get_child(:sink),

      #
      get_child(:tee_video)
      |> via_out(:master)
      |> via_in(Pad.ref(:input, :video),
        options: [encoding: :H264, segment_duration: Membrane.Time.seconds(2)]
      )
      |> get_child(:sink)
    ]

    {[spec: spec], %{socket: socket, video: video, native: nil}}
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
      child(ref, %Algora.Sink{
        rtmp_url: url,
        pid: self(),
        native: state.native
      }),

      #
      get_child(:tee_audio)
      |> via_out(:copy)
      |> via_in(Pad.ref(:audio, 0), toilet_capacity: 10_000)
      # |> via_in(Pad.ref(:audio, 0))
      |> get_child(ref),

      #
      get_child(:tee_video)
      |> via_out(:copy)
      |> via_in(Pad.ref(:video, 0), toilet_capacity: 10_000)
      # |> via_in(Pad.ref(:video, 0))
      |> get_child(ref)
    ]

    {[spec: spec], state}
  end

  def handle_info({:init, native}, _ctx, state) do
    {[], %{state | native: native}}
  end

  def handle_info(:multicast_algora, _ctx, state) do
    send(
      self(),
      {:forward_rtmp, "rtmp://localhost:9006/3wactacTCNZIiUHa2EGSDnxvzBZHcFrh5IQ-czPZFXo",
       String.to_atom("rtmp_sink_algora_0")}
    )

    # user = Algora.Accounts.get_user_by!(handle: "algora")
    # destinations = Algora.Accounts.list_active_destinations(user.id)

    # for {destination, i} <- Enum.with_index(destinations) do
    #   url =
    #     URI.new!(destination.rtmp_url)
    #     |> URI.append_path("/" <> destination.stream_key)
    #     |> URI.to_string()
    #
    # send(self(), {:forward_rtmp, url, String.to_atom("rtmp_sink_algora_#{i}")})
    # end

    # if url = Algora.Accounts.get_restream_ws_url(user) do
    #   Task.Supervisor.start_child(
    #     Algora.TaskSupervisor,
    #     fn -> Algora.Restream.Websocket.start_link(%{url: url, video: state.video}) end,
    #     restart: :transient
    #   )
    # end

    {[], state}
    # {[stream_format: {pad, %AAC{config: {:audio_specific_config, packet.payload}}}], state}
  end

  @impl true
  def handle_call(:get_video_id, _ctx, state) do
    {[{:reply, state.video.id}], state}
  end
end
