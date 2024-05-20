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
        mode: :live,
        manifest_module: Membrane.HTTPAdaptiveStream.HLS,
        target_window_duration: :infinity,
        persist?: false,
        storage: %Algora.Storage{video: video}
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
      |> via_in(Pad.ref(:input, :audio_sink),
        options: [encoding: :AAC, segment_duration: Membrane.Time.seconds(2)]
      )
      |> get_child(:sink),

      #
      get_child(:tee_video)
      |> via_out(:master)
      |> via_in(Pad.ref(:input, :video_sink),
        options: [encoding: :H264, segment_duration: Membrane.Time.seconds(2)]
      )
      |> get_child(:sink)
    ]

    {[spec: spec], %{socket: socket, video: video}}
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
      |> via_in(Pad.ref(:audio, 0))
      |> get_child(ref),

      #
      get_child(:tee_video)
      |> via_out(:copy)
      |> via_in(Pad.ref(:video, 0))
      |> get_child(ref)
    ]

    {[spec: spec], state}
  end

  @impl true
  def handle_call(:get_video_id, _ctx, state) do
    {[{:reply, state.video.id}], state}
  end
end
