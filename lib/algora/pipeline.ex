defmodule Algora.Pipeline do
  alias Algora.Library
  use Membrane.Pipeline

  @impl true
  def handle_init(_context, socket: socket) do
    video = Library.init_livestream!()

    spec = [
      #
      child(:tee, Membrane.Tee.Master),

      #
      child(:src, %Membrane.RTMP.Source{
        socket: socket,
        validator: %Algora.MessageValidator{video_id: video.id}
      })
      |> get_child(:tee),

      #
      child(:sink, %Membrane.HTTPAdaptiveStream.SinkBin{
        mode: :live,
        manifest_module: Membrane.HTTPAdaptiveStream.HLS,
        target_window_duration: :infinity,
        persist?: false,
        storage: %Algora.Storage{video: video}
      }),

      #
      get_child(:tee)
      |> via_out(:master)
      |> child(:demuxer, Membrane.FLV.Demuxer),

      #
      get_child(:demuxer)
      |> via_out(Pad.ref(:video, 0))
      |> child(:video_parser, Membrane.H264.Parser)
      |> via_in(Pad.ref(:input, :video),
        options: [encoding: :H264, segment_duration: Membrane.Time.seconds(2)]
      )
      |> get_child(:sink),

      #
      get_child(:demuxer)
      |> via_out(Pad.ref(:audio, 0))
      |> child(:audio_parser, %Membrane.AAC.Parser{out_encapsulation: :none})
      |> via_in(Pad.ref(:input, :audio),
        options: [encoding: :AAC, segment_duration: Membrane.Time.seconds(2)]
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
    case :gen_tcp.controlling_process(socket, source) do
      :ok ->
        :ok

      {:error, :not_owner} ->
        Process.send_after(self(), notification, 200)
    end

    {[], state}
  end

  @impl true
  def handle_call(:get_video_id, _ctx, state) do
    {[{:reply, state.video.id}], state}
  end
end
