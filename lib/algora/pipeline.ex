defmodule Algora.Pipeline do
  alias Algora.Library
  use Membrane.Pipeline

  @impl true
  def handle_init(_context, socket: socket) do
    video = Library.init_livestream!()
    # init(socket, %{video: video, counter: 0})

    spec = [
      #
      child(:src, %Algora.SourceBin{
        socket: socket,
        validator: %Algora.MessageValidator{video_id: video.id, pid: self()}
      }),

      #
      child(:sink, %Algora.SinkBin{
        mode: :live,
        manifest_module: Membrane.HTTPAdaptiveStream.HLS,
        target_window_duration: :infinity,
        persist?: false,
        storage: %Algora.Storage{video: video}
      }),

      #
      get_child(:src)
      |> via_out(:audio)
      # |> via_in(Pad.ref(:input, 0))
      |> child(:tee_audio, Membrane.Tee.Master),

      #
      get_child(:src)
      |> via_out(:video)
      # |> via_in(Pad.ref(:input, 0))
      |> child(:tee_video, Membrane.Tee.Master),

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

    {[spec: spec], %{socket: socket, video: video, counter: 0}}
  end

  @impl true
  def handle_child_notification(
        {:socket_control_needed, _socket, source} = notification,
        _element,
        _ctx,
        state
      ) do
    dbg(notification, label: "handle_child_notification")
    dbg(source, label: "socket_control_needed[source]")
    send(self(), notification)
    {[], state}
  end

  @impl true
  def handle_child_notification(:end_of_stream = notification, _element, _ctx, state) do
    dbg(notification, label: "handle_child_notification")
    Algora.Library.toggle_streamer_live(state.video, false)

    # spec = [
    #   get_child(:src),
    #   get_child(:sink)
    # ]

    # TODO: gracefully terminate open connections (e.g. RTMP, WS)
    {[], state}
  end

  @impl true
  def handle_child_notification(notification, _element, _ctx, state) do
    dbg(notification, label: "handle_child_notification")
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

  def handle_info({:new_conn, socket}, _ctx, state) do
    # dbg(socket, label: "handle_call")

    dbg(:new_conn, label: "handle_info")
    init(socket, state)
  end

  def handle_info({:do, actions}, _ctx, state) do
    {actions, state}
  end

  @impl true
  def handle_terminate_request(_ctx, state), do: {[], state}

  @impl true
  def handle_call(:get_video_id, _ctx, state) do
    {[{:reply, state.video.id}], state}
  end

  def handle_call(:get_socket, _ctx, state) do
    {[{:reply, state.socket}], state}
  end

  def handle_call(:state, _ctx, state) do
    {[{:reply, state}], state}
  end

  defp xref(atom, counter), do: String.to_atom("#{atom}_#{counter}")

  defp init(socket, state) do
    :ok = Membrane.RTMP.SourceBin.pass_control(socket, self())

    # spec = [
    #   child(xref(:src, state.counter), %Membrane.RTMP.SourceBin{
    #     socket: socket,
    #     validator: %Algora.MessageValidator{video_id: state.video.id, pid: self()}
    #   }),

    #   #
    #   get_child(xref(:src, state.counter))
    #   |> via_out(:audio)
    #   # |> via_in(Pad.ref(:input, 0))
    #   |> child(xref(:tee_audio, state.counter), Membrane.Tee.Master),

    #   #
    #   get_child(xref(:src, state.counter))
    #   |> via_out(:video)
    #   # |> via_in(Pad.ref(:input, 0))
    #   |> child(xref(:tee_video, state.counter), Membrane.Tee.Master),

    #   #
    #   get_child(xref(:tee_audio, state.counter))
    #   |> via_out(:master)
    #   |> via_in(Pad.ref(:input, :audio),
    #     options: [encoding: :AAC, segment_duration: Membrane.Time.seconds(2)]
    #   )
    #   |> get_child(:sink),

    #   #
    #   get_child(xref(:tee_video, state.counter))
    #   |> via_out(:master)
    #   |> via_in(Pad.ref(:input, :video),
    #     options: [encoding: :H264, segment_duration: Membrane.Time.seconds(2)]
    #   )
    #   |> get_child(:sink)
    # ]

    # {[spec: spec], %{state | socket: socket, counter: state.counter + 1}}
    {[
       notify_child:
         {:src,
          {:new_conn,
           %{
             socket: socket,
             validator: %Algora.MessageValidator{video_id: state.video.id, pid: self()},
             use_ssl?: false
           }}}
     ], %{state | socket: socket, counter: state.counter + 1}}
  end
end
