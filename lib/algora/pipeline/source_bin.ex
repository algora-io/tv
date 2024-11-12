defmodule Algora.Pipeline.SourceBin do
  @moduledoc """
  Bin responsible for demuxing and parsing an RTMP stream.

  Outputs single audio and video which are ready for further processing with Membrane Elements.
  At this moment only AAC and H264 codecs are supported.

  ## Usage

  The bin requires the RTMP client to be already connected to the socket.
  The socket passed to the bin must be in non-active mode (`active` set to `false`).

  When the `Membrane.RTMP.Source` is initialized the bin sends `t:Membrane.RTMP.Source.socket_control_needed_t/0` notification.
  Then, the control of the socket should be immediately granted to the `Source` with the `pass_control/2`,
  and the `Source` will start reading packets from the socket.

  The bin allows for providing custom validator module, that verifies some of the RTMP messages.
  The module has to implement the `Membrane.RTMP.MessageValidator` protocol.
  If the validation fails, a `t:Membrane.RTMP.Source.stream_validation_failed_t/0` notification is sent.
  """
  use Membrane.Bin

  alias Membrane.{AAC, H264, RTMP}

  def_output_pad(:video,
    accepted_format: H264,
    availability: :always
  )

  def_output_pad(:audio,
    accepted_format: AAC,
    availability: :always
  )

  def_options(
    socket: [
      spec: :gen_tcp.socket() | :ssl.sslsocket(),
      description: """
      Socket, on which the bin will receive RTMP or RTMPS stream. The socket will be passed to the `RTMP.Source`.
      The socket must be already connected to the RTMP client and be in non-active mode (`active` set to `false`).

      In case of RTMPS the `use_ssl?` options must be set to true.
      """
    ],
    use_ssl?: [
      spec: boolean(),
      default: false,
      description: """
      Tells whether the passed socket is a regular TCP socket or SSL one.
      """
    ],
    validator: [
      spec: Membrane.RTMP.MessageValidator.t(),
      description: """
      A `Membrane.RTMP.MessageValidator` implementation, used for validating the stream. By default allows
      every incoming stream.
      """,
      default: %Membrane.RTMP.MessageValidator.Default{}
    ]
  )

  @impl true
  def handle_init(_ctx, %__MODULE__{} = opts) do
    transcode? = Algora.Env.get(:transcode?)

    structure = [
      child(:src, %RTMP.Source{
        socket: opts.socket,
        validator: opts.validator,
        use_ssl?: opts.use_ssl?
      })
      |> child(:demuxer, Algora.Pipeline.Demuxer),
      #
      child(:audio_parser, %Membrane.AAC.Parser{
        out_encapsulation: :none
      }),
      child(:video_parser, %Membrane.H264.Parser{
        output_stream_structure: if(transcode?, do: :annexb, else: :avc1),
        repeat_parameter_sets: true
      }),
      #
      get_child(:demuxer)
      |> via_out(Pad.ref(:audio, 0))
      |> get_child(:audio_parser)
      |> bin_output(:audio),
      #
      get_child(:demuxer)
      |> via_out(Pad.ref(:video, 0))
      |> get_child(:video_parser)
      |> then(fn parser ->
        if transcode? do
          parser
          |> child(:decoder, Membrane.H264.FFmpeg.Decoder)
          |> child(:encoder, %Membrane.H264.FFmpeg.Encoder{
            preset: :ultrafast,
            crf: 30,
            tune: :zerolatency
          })
        else
          parser
        end
      end)
      |> bin_output(:video)
    ]

    {[spec: structure], %{}}
  end

  @impl true
  def handle_child_notification(
        {type, _socket, _pid} = notification,
        :src,
        _ctx,
        state
      )
      when type in [:socket_control_needed, :ssl_socket_control_needed] do
    {[notify_parent: notification], state}
  end

  def handle_child_notification(
        {type, _stage, _reason} = notification,
        :src,
        _ctx,
        state
      )
      when type in [:stream_validation_success, :stream_validation_error] do
    {[notify_parent: notification], state}
  end

  @doc """
  Passes the control of the socket to the `source`.

  To succeed, the executing process must be in control of the socket, otherwise `{:error, :not_owner}` is returned.
  """
  @spec pass_control(:gen_tcp.socket(), pid()) :: :ok | {:error, atom()}
  def pass_control(socket, source) do
    :gen_tcp.controlling_process(socket, source)
  end

  @doc """
  Passes the control of the ssl socket to the `source`.

  To succeed, the executing process must be in control of the socket, otherwise `{:error, :not_owner}` is returned.
  """
  @spec secure_pass_control(:ssl.sslsocket(), pid()) :: :ok | {:error, any()}
  def secure_pass_control(socket, source) do
    :ssl.controlling_process(socket, source)
  end
end
