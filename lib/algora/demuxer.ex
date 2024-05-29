defmodule Algora.Demuxer do
  @moduledoc """
  Element for demuxing FLV streams into audio and video streams.
  FLV format supports only one video and audio stream.
  They are optional however, FLV without either audio or video is also possible.

  When a new FLV stream is detected and an output pad for it has not been linked yet, the element will notify its parent
  with `t:new_stream_notification_t/0` and start buffering the packets for the stream until the requested output pad is
  linked. Please note that if the parent ignores the notification, the element will eventually raise an error as it can't
  buffer the incoming packets indefinitely.

  If you want to pre-link the pipeline instead of linking dynamically on new stream notifications, you can use the
  following output pads:
  - `Pad.ref(:audio, 0)` for audio stream
  - `Pad.ref(:video, 0)` for video stream
  The `0` in the pad reference is the stream ID and according to the FLV specification, it must always be 0.

  ## Note
  The demuxer implements the [Enhanced RTMP specification](https://github.com/veovera/enhanced-rtmp) in terms of parsing.
  It does NOT support processing of the protocols other than H264 and AAC.
  """
  use Membrane.Filter

  require Membrane.Logger

  alias Membrane.{AAC, Buffer, FLV, H264}
  alias Membrane.FLV.Parser
  alias Membrane.RemoteStream

  @typedoc """
  Type of notification that is sent when a new FLV stream is detected.
  """
  @type new_stream_notification_t() :: {:new_stream, Membrane.Pad.ref(), codec_t()}

  @typedoc """
  Notification that is sent when the demuxer encounters a video codec that is not supported by the element.
  """
  @type unsupported_codec_notification_t() ::
          {:unsupported_codec, FLV.video_codec_t() | :AV1 | :HEVC | :VP9}

  @typedoc """
  List of formats supported by the demuxer.

  For video, only H264 is supported. Other video codecs will result in `t:unsupported_codec_notification_t/0` and
  dropping all the following packets on all pads, expecting the parent to shut down.
  Audio codecs other than AAC might not work correctly, although they won't throw any errors.
  """
  @type codec_t() :: FLV.audio_codec_t() | :H264

  def_input_pad(:input,
    availability: :always,
    accepted_format:
      %RemoteStream{content_format: content_format, type: :bytestream}
      when content_format in [nil, FLV]
  )

  def_output_pad(:audio,
    availability: :on_request,
    accepted_format:
      any_of(
        RemoteStream,
        %AAC{encapsulation: :none, config: {:audio_specific_config, _config}}
      )
  )

  def_output_pad(:video,
    availability: :on_request,
    accepted_format: %H264{stream_structure: {:avc3, _dcr}}
  )

  @impl true
  def handle_init(_ctx, _opts) do
    {[],
     %{
       partial: <<>>,
       pads_buffer: %{},
       aac_asc: <<>>,
       awaiting_header?: true,
       ignored_packets: 0
     }}
  end

  def handle_parent_notification({:new_conn, _opts} = notification, _ctx, _state) do
    dbg(notification, label: "handle_parent_notification")

    {[],
     %{
       partial: <<>>,
       pads_buffer: %{},
       aac_asc: <<>>,
       awaiting_header?: true,
       ignored_packets: 0
     }}
  end

  @impl true
  def handle_stream_format(_pad, _stream_format, _context, state), do: {[], state}

  @max_ignored_packets 300
  @impl true
  def handle_buffer(:input, _buffer, _ctx, %{ignored_packets: ignored_packets} = state)
      when ignored_packets > 0 do
    if ignored_packets >= @max_ignored_packets do
      raise "Too many ignored packets..."
    end

    {[], %{state | ignored_packets: ignored_packets + 1}}
  end

  @impl true
  def handle_buffer(:input, buffer, _ctx, %{awaiting_header?: true} = state) do
    header = state.partial <> buffer.payload

    case Membrane.FLV.Parser.parse_header(header) do
      {:ok, _header, rest} ->
        {[], %{state | partial: rest, awaiting_header?: false}}

      {:error, :not_enough_data} ->
        {[], %{state | partial: header}}

      {:error, :not_a_header} ->
        raise("Invalid data detected on the input. Expected FLV header")
    end
  end

  @impl true
  def handle_buffer(:input, buffer, _ctx, %{awaiting_header?: false} = state) do
    body = state.partial <> buffer.payload

    case Parser.parse_body(body) do
      {:ok, packets, rest} ->
        {actions, state} = get_actions(packets, state)
        {actions, %{state | partial: rest}}

      {:error, :not_enough_data} ->
        {[], %{state | partial: body}}

      {:error, {:unsupported_codec, codec}} ->
        {[notify_parent: {:unsupported_codec, codec}],
         %{ignored_packets: state.ignored_packets + 1}}
    end
  end

  @impl true
  def handle_pad_added(pad, _ctx, state) do
    actions =
      case Map.fetch(state.pads_buffer, pad) do
        {:ok, buffer} ->
          [{:stop_timer, {:link_timeout, pad}} | Enum.to_list(buffer)]

        :error ->
          []
      end

    {actions, put_in(state, [:pads_buffer, pad], :connected)}
  end

  # currently Membrane Core's callback typespec doesn't allow for functions that always raise
  @dialyzer {:nowarn_function, handle_tick: 3}
  @impl true
  def handle_tick({:link_timeout, pad}, _ctx, _state) do
    raise """
    Exceeded the link timeout for pad #{inspect(pad)}.
    Make sure to link the corresponding output pad on :new_stream notification.
    """
  end

  @impl true
  def handle_end_of_stream(:input, _ctx, state) do
    Enum.reduce(state.pads_buffer, {[], state}, fn {pad, value}, {actions, state} ->
      eos = {:end_of_stream, pad}

      case value do
        :connected -> {[eos | actions], state}
        buffer -> {actions, put_in(state, [:pads_buffer, pad], Qex.push(buffer, eos))}
      end
    end)
  end

  defp get_actions(packets, state, actions \\ [])

  defp get_actions([], state, actions), do: {actions, state}

  defp get_actions([packet | rest], state, actions) do
    pad = pad(packet)

    pts = Membrane.Time.milliseconds(packet.pts)
    dts = Membrane.Time.milliseconds(packet.dts)

    {new_actions, state} =
      case packet do
        %{type: :audio_config, codec: :AAC} ->
          Membrane.Logger.debug("Audio configuration received")

          {[stream_format: {pad, %AAC{config: {:audio_specific_config, packet.payload}}}], state}

        %{type: :audio_config} ->
          {[
             stream_format: {pad, %RemoteStream{content_format: packet.codec}},
             buffer: {pad, %Buffer{pts: pts, dts: dts, payload: packet.payload}}
           ], state}

        %{type: :video_config, codec: :H264} ->
          Membrane.Logger.debug("Video configuration received")

          {[
             stream_format:
               {pad, %H264{alignment: :nalu, stream_structure: {:avc3, packet.payload}}}
           ], state}

        %{type: :video_config, codec: codec} when codec in [:AV1, :HEVC, :VP9] ->
          {[notify_parent: {:unsupported_codec, packet.codec}],
           %{state | ignored_packets: state.ignored_packets + 1}}

        _media_packet ->
          buffer = %Buffer{
            pts: pts,
            dts: dts,
            metadata: get_metadata(packet),
            payload: packet.payload
          }

          {[buffer: {pad, buffer}], state}
      end

    {out_actions, state} =
      Enum.flat_map_reduce(new_actions, state, fn action, state ->
        buffer_or_send(action, packet, state)
      end)

    get_actions(rest, state, actions ++ out_actions)
  end

  # actions that don't need an output pad shouldn't be buffered
  defp buffer_or_send({:notify_parent, _notification} = action, _packet, state) do
    {[action], state}
  end

  @link_timeout 5_000
  defp buffer_or_send(action, packet, state) do
    pad = pad(packet)

    case Map.fetch(state.pads_buffer, pad) do
      {:ok, :connected} ->
        {[action], state}

      {:ok, buffer} ->
        state = put_in(state, [:pads_buffer, pad], Qex.push(buffer, action))

        {[], state}

      :error ->
        state = put_in(state, [:pads_buffer, pad], Qex.new([action]))

        {[
           notify_parent: {:new_stream, pad, packet.codec},
           start_timer: {{:link_timeout, pad}, Membrane.Time.milliseconds(@link_timeout)}
         ], state}
    end
  end

  defp get_metadata(%FLV.Packet{type: :video, codec_params: %{key_frame?: key_frame?}}),
    do: %{key_frame?: key_frame?}

  defp get_metadata(_packet), do: %{}

  defp pad(%FLV.Packet{type: type, stream_id: stream_id}) do
    type =
      case type do
        :audio -> :audio
        :audio_config -> :audio
        :video -> :video
        :video_config -> :video
      end

    Pad.ref(type, stream_id)
  end
end
