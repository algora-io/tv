defmodule Algora.Source do
  @moduledoc """
  Membrane Element for receiving an RTMP stream. Acts as a RTMP Server.

  When initializing, the source sends `t:socket_control_needed_t/0` notification,
  upon which it should be granted the control over the `socket` via `:gen_tcp.controlling_process/2`.

  The Source allows for providing custom validator module, that verifies some of the RTMP messages.
  The module has to implement the `Membrane.RTMP.MessageValidator` behaviour.
  If the validation fails, the socket gets closed and the parent is notified with `t:stream_validation_failed_t/0`.

  This implementation is limited to only AAC and H264 streams.
  """
  use Membrane.Source

  require Membrane.Logger

  alias Membrane.RTMP.{Handshake, MessageHandler, MessageParser}

  def_output_pad(:output,
    availability: :always,
    accepted_format: Membrane.RemoteStream,
    flow_control: :manual
  )

  def_options(
    socket: [
      spec: :gen_tcp.socket() | :ssl.sslsocket(),
      description: """
      Socket on which the source will be receiving the RTMP or RTMPS stream.
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

  @typedoc """
  Notification sent when the RTMP Source element is initialized and it should be granted control over the socket using `:gen_tcp.controlling_process/2`.
  """
  @type socket_control_needed_t() :: {:socket_control_needed, :gen_tcp.socket(), pid()}

  @typedoc """
  Same as `t:socket_control_needed_t/0` but for secured socket meant for RTMPS.
  """
  @type ssl_socket_control_needed_t() :: {:ssl_socket_control_needed, :ssl.sslsocket(), pid()}

  @type validation_stage_t :: :publish | :release_stream | :set_data_frame

  @typedoc """
  Notification sent when the validator approves given validation stage.
  """
  @type stream_validation_success_t() ::
          {:stream_validation_success, validation_stage_t(), result :: any()}

  @typedoc """
  Notification sent when the validator denies incoming RTMP stream.
  """
  @type stream_validation_failed_t() ::
          {:stream_validation_failed, validation_stage_t(), reason :: any()}

  @typedoc """
  Notification sent when the socket has been closed but no media data has flown through it.

  This notification is only sent when the `:output` pad never reaches `:start_of_stream`.
  """
  @type unexpected_socket_closed_t() :: :unexpected_socket_closed

  @impl true
  def handle_init(_ctx, %__MODULE__{} = opts) do
    state =
      opts
      |> Map.from_struct()
      |> Map.merge(%{
        actions: [],
        header_sent?: false,
        message_parser: MessageParser.init(Handshake.init_server()),
        receiver_pid: nil,
        socket_ready?: false,
        # how many times the Source tries to get control of the socket
        socket_retries: 3,
        # epoch required for performing a handshake with the pipeline
        epoch: 0,
        socket_module: if(opts.use_ssl?, do: :ssl, else: :gen_tcp)
      })

    notification_type =
      if opts.use_ssl?, do: :ssl_socket_control_needed, else: :socket_control_needed

    {[notify_parent: {notification_type, state.socket, self()}], state}
  end

  @impl true
  def handle_playing(_ctx, state) do
    target_pid = self()

    use_ssl? = state.use_ssl?

    {:ok, receiver_process} =
      Task.start_link(fn ->
        if use_ssl? do
          receive_ssl_loop(state.socket, target_pid)
        else
          receive_loop(state.socket, target_pid)
        end
      end)

    send(self(), :start_receiving)

    stream_format = [
      stream_format:
        {:output, %Membrane.RemoteStream{content_format: Membrane.FLV, type: :bytestream}}
    ]

    {stream_format, %{state | receiver_pid: receiver_process}}
  end

  defp receive_ssl_loop(socket, target) do
    receive do
      {:ssl, _port, packet} ->
        send(target, {:socket, socket, packet})

      {:ssl_closed, _port} ->
        send(target, {:socket_closed, socket})

      :terminate ->
        exit(:normal)

      _message ->
        :noop
    end

    receive_ssl_loop(socket, target)
  end

  defp receive_loop(socket, target) do
    receive do
      {:tcp, _port, packet} ->
        send(target, {:socket, socket, packet})

      {:tcp_closed, _port} ->
        send(target, {:socket_closed, socket})

      :terminate ->
        exit(:normal)

      _message ->
        :noop
    end

    receive_loop(socket, target)
  end

  @impl true
  def handle_demand(_pad, _size, _unit, _ctx, state) when state.socket_ready? do
    if state.use_ssl? do
      :ssl.setopts(state.socket, active: :once)
    else
      :inet.setopts(state.socket, active: :once)
    end

    {[], state}
  end

  @impl true
  def handle_demand(_pad, _size, _unit, _ctx, state) do
    {[], state}
  end

  @impl true
  def handle_terminate_request(_ctx, state) do
    send(state.receiver_pid, :terminate)
    {[terminate: :normal], %{state | receiver_pid: nil}}
  end

  @impl true
  def handle_info(:start_receiving, _ctx, %{socket_retries: 0} = state) do
    Membrane.Logger.warning("Failed to take control of the socket")
    {[], state}
  end

  def handle_info(:start_receiving, _ctx, %{socket_retries: retries} = state) do
    module = if state.use_ssl?, do: :ssl, else: :gen_tcp

    case module.controlling_process(state.socket, state.receiver_pid) do
      :ok ->
        if state.use_ssl? do
          :ok = :ssl.setopts(state.socket, active: :once)
        else
          :ok = :inet.setopts(state.socket, active: :once)
        end

        {[], %{state | socket_ready?: true}}

      {:error, :not_owner} ->
        Process.send_after(self(), :start_receiving, 200)
        {[], %{state | socket_retries: retries - 1}}
    end
  end

  @impl true
  def handle_info({:socket, socket, packet}, _ctx, %{socket: socket} = state) do
    {messages, message_parser} =
      MessageHandler.parse_packet_messages(packet, state.message_parser)

    state = MessageHandler.handle_client_messages(messages, state)

    {state.actions, %{state | actions: [], message_parser: message_parser}}
  end

  @impl true
  def handle_info({:socket_closed, _socket}, ctx, state) do
    cond do
      ctx.pads.output.end_of_stream? -> {[], state}
      ctx.pads.output.start_of_stream? -> {[end_of_stream: :output], state}
      true -> {[notify_parent: :unexpected_socket_closed, end_of_stream: :output], state}
    end
  end

  @impl true
  def handle_info(_message, _ctx, state) do
    {[], state}
  end

  @impl true
  def handle_parent_notification({:new_conn, opts} = notification, _ctx, _state) do
    dbg(notification, label: "handle_parent_notification")

    state =
      opts
      |> Map.merge(%{
        actions: [],
        header_sent?: false,
        message_parser: MessageParser.init(Handshake.init_server()),
        receiver_pid: nil,
        socket_ready?: false,
        # how many times the Source tries to get control of the socket
        socket_retries: 3,
        # epoch required for performing a handshake with the pipeline
        epoch: 0,
        socket_module: if(opts.use_ssl?, do: :ssl, else: :gen_tcp)
      })

    notification_type =
      if opts.use_ssl?, do: :ssl_socket_control_needed, else: :socket_control_needed

    {[notify_parent: {notification_type, state.socket, self()}], state}
  end
end
