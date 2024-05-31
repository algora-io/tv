defmodule Algora.Sink do
  @moduledoc """
  Membrane element being client-side of RTMP streams.
  It needs to receive at least one of: video stream in H264 format or audio in AAC format.
  Currently it supports only:
    - RTMP proper - "plain" RTMP protocol
    - RTMPS - RTMP over TLS/SSL
  other RTMP variants - RTMPT, RTMPE, RTMFP are not supported.
  Implementation based on FFmpeg.
  """
  use Membrane.Sink

  require Membrane.{H264, Logger}

  alias Membrane.RTMP.Sink.Native
  alias Membrane.{AAC, Buffer, H264}

  @supported_protocols ["rtmp://", "rtmps://"]
  @connection_attempt_interval 500
  @type track_type :: :audio | :video

  def_input_pad(:audio,
    availability: :on_request,
    accepted_format: AAC,
    flow_control: :manual,
    demand_unit: :buffers
  )

  def_input_pad(:video,
    availability: :on_request,
    accepted_format: %H264{stream_structure: structure} when H264.is_avc(structure),
    flow_control: :manual,
    demand_unit: :buffers
  )

  def_options(
    rtmp_url: [
      spec: String.t(),
      description: """
      Destination URL of the stream. It needs to start with rtmp:// or rtmps:// depending on the protocol variant.
      This URL should be provided by your streaming service.
      """
    ],
    max_attempts: [
      spec: pos_integer() | :infinity,
      default: 1,
      description: """
      Maximum number of connection attempts before failing with an error.
      The attempts will happen every #{@connection_attempt_interval} ms
      """
    ],
    tracks: [
      spec: [track_type()],
      default: [:audio, :video],
      description: """
      A list of tracks, which will be sent. Can be `:audio`, `:video` or both.
      """
    ]
  )

  @impl true
  def handle_init(_ctx, options) do
    unless String.starts_with?(options.rtmp_url, @supported_protocols) do
      raise ArgumentError, "Invalid destination URL provided"
    end

    unless options.max_attempts == :infinity or
             (is_integer(options.max_attempts) and options.max_attempts >= 1) do
      raise ArgumentError, "Invalid max_attempts option value: #{options.max_attempts}"
    end

    options = %{options | tracks: Enum.uniq(options.tracks)}

    unless length(options.tracks) > 0 and
             Enum.all?(options.tracks, &Kernel.in(&1, [:audio, :video])) do
      raise ArgumentError, "All track have to be either :audio or :video"
    end

    single_track? = length(options.tracks) == 1
    frame_buffer = Enum.map(options.tracks, &{Pad.ref(&1, 0), nil}) |> Enum.into(%{})

    state =
      options
      |> Map.from_struct()
      |> Map.merge(%{
        attempts: 0,
        native: nil,
        # Keys here are the pad names.
        frame_buffer: frame_buffer,
        ready?: false,
        # Activated when one of the source inputs gets closed. Interleaving is
        # disabled, frame buffer is flushed and from that point buffers on the
        # remaining pad are simply forwarded to the output.
        # Always on if a single track is connected
        forward_mode?: single_track?,
        video_base_dts: nil
      })

    {[], state}
  end

  @impl true
  def handle_setup(_ctx, state) do
    audio? = :audio in state.tracks
    video? = :video in state.tracks

    {:ok, native} = Native.create(state.rtmp_url, audio?, video?)

    state
    |> Map.put(:native, native)
    |> try_connect()
    |> then(&{[], &1})
  end

  @impl true
  def handle_playing(_ctx, state) do
    {build_demand(state), state}
  end

  @impl true
  def handle_pad_added(Pad.ref(_type, stream_id), _ctx, _state) when stream_id != 0,
    do: raise(ArgumentError, message: "Stream id must always be 0")

  @impl true
  def handle_pad_added(_pad, _ctx, state) do
    {[], state}
  end

  @impl true
  def handle_stream_format(
        Pad.ref(:video, 0),
        %H264{width: width, height: height, stream_structure: {_avc, dcr}},
        _ctx,
        state
      ) do
    case Native.init_video_stream(state.native, width, height, dcr) do
      {:ok, ready?, native} ->
        Membrane.Logger.debug("Correctly initialized video stream.")
        {[], %{state | native: native, ready?: ready?}}

      {:error, :stream_format_resent} ->
        Membrane.Logger.warning(
          "Input stream format redefined on pad :video. RTMP Sink does not support dynamic stream parameters"
        )

        {[], state}
    end
  end

  @impl true
  def handle_stream_format(Pad.ref(:audio, 0), %Membrane.AAC{} = stream_format, _ctx, state) do
    profile = AAC.profile_to_aot_id(stream_format.profile)
    sr_index = AAC.sample_rate_to_sampling_frequency_id(stream_format.sample_rate)
    channel_configuration = AAC.channels_to_channel_config_id(stream_format.channels)
    frame_length_id = AAC.samples_per_frame_to_frame_length_id(stream_format.samples_per_frame)

    aac_config =
      <<profile::5, sr_index::4, channel_configuration::4, frame_length_id::1, 0::1, 0::1>>

    case Native.init_audio_stream(
           state.native,
           stream_format.channels,
           stream_format.sample_rate,
           aac_config
         ) do
      {:ok, ready?, native} ->
        Membrane.Logger.debug("Correctly initialized audio stream.")
        {[], %{state | native: native, ready?: ready?}}

      {:error, :stream_format_resent} ->
        Membrane.Logger.warning(
          "Input stream format redefined on pad :audio. RTMP Sink does not support dynamic stream parameters"
        )

        {[], state}
    end
  end

  @impl true
  def handle_buffer(pad, buffer, _ctx, %{ready?: false} = state) do
    {[], fill_frame_buffer(state, pad, buffer)}
  end

  def handle_buffer(pad, buffer, _ctx, %{forward_mode?: true} = state) do
    {[demand: pad], write_frame(state, pad, buffer)}
  end

  def handle_buffer(pad, buffer, _ctx, state) do
    state
    |> fill_frame_buffer(pad, buffer)
    |> write_frame_interleaved()
  end

  @impl true
  def handle_end_of_stream(Pad.ref(type, 0), _ctx, state) do
    if state.forward_mode? do
      Native.finalize_stream(state.native)
      {[], state}
    else
      # The interleave logic does not work if either one of the inputs does not
      # produce buffers. From this point on we act as a "forward" filter.
      other_pad =
        case type do
          :audio -> :video
          :video -> :audio
        end
        |> then(&Pad.ref(&1, 0))

      state = flush_frame_buffer(state)
      {[demand: other_pad], %{state | forward_mode?: true}}
    end
  end

  defp try_connect(%{attempts: attempts, max_attempts: max_attempts} = state)
       when max_attempts != :infinity and attempts >= max_attempts do
    raise "failed to connect to '#{state.rtmp_url}' #{attempts} times, aborting"
  end

  defp try_connect(state) do
    state = %{state | attempts: state.attempts + 1}

    case Native.try_connect(state.native) do
      :ok ->
        Membrane.Logger.debug("Correctly initialized connection with: #{state.rtmp_url}")

        state

      {:error, error} when error in [:econnrefused, :etimedout] ->
        Membrane.Logger.warning(
          "Connection to #{state.rtmp_url} refused, retrying in #{@connection_attempt_interval}ms"
        )

        Process.sleep(@connection_attempt_interval)

        try_connect(state)

      {:error, reason} ->
        raise "failed to connect to '#{state.rtmp_url}': #{inspect(reason)}"
    end
  end

  defp build_demand(%{frame_buffer: frame_buffer}) do
    frame_buffer
    |> Enum.filter(fn {_pad, buffer} -> buffer == nil end)
    |> Enum.map(fn {pad, _buffer} -> {:demand, pad} end)
  end

  defp fill_frame_buffer(state, pad, buffer) do
    if get_in(state, [:frame_buffer, pad]) == nil do
      put_in(state, [:frame_buffer, pad], buffer)
    else
      raise "attempted to overwrite frame buffer on pad #{inspect(pad)}"
    end
  end

  defp write_frame_interleaved(
         %{
           frame_buffer: %{Pad.ref(:audio, 0) => audio, Pad.ref(:video, 0) => video}
         } = state
       )
       when audio == nil or video == nil do
    # We still have to wait for the other frame.
    {[], state}
  end

  defp write_frame_interleaved(%{frame_buffer: frame_buffer} = state) do
    {pad, buffer} =
      Enum.min_by(frame_buffer, fn {_pad, buffer} ->
        buffer
        |> Buffer.get_dts_or_pts()
        |> Ratio.ceil()
      end)

    state =
      state
      |> write_frame(pad, buffer)
      |> put_in([:frame_buffer, pad], nil)

    {build_demand(state), state}
  end

  defp flush_frame_buffer(%{frame_buffer: frame_buffer} = state) do
    pads_with_buffer =
      frame_buffer
      |> Enum.filter(fn {_pad, buffer} -> buffer != nil end)
      |> Enum.sort(fn {_, left}, {_, right} ->
        Buffer.get_dts_or_pts(left) <= Buffer.get_dts_or_pts(right)
      end)

    Enum.reduce(pads_with_buffer, state, fn {pad, buffer}, state ->
      state
      |> write_frame(pad, buffer)
      |> put_in([:frame_buffer, pad], nil)
    end)
  end

  defp write_frame(state, Pad.ref(:audio, 0), buffer) do
    buffer_pts = Ratio.ceil(buffer.pts)

    case Native.write_audio_frame(state.native, buffer.payload, buffer_pts) do
      {:ok, native} ->
        Map.put(state, :native, native)

      {:error, reason} ->
        raise "writing audio frame failed with reason: #{inspect(reason)}"
    end
  end

  defp write_frame(state, Pad.ref(:video, 0), buffer) do
    dts = buffer.dts || buffer.pts
    pts = buffer.pts || buffer.dts
    {base_dts, state} = Bunch.Map.get_updated!(state, :video_base_dts, &(&1 || dts))

    case Native.write_video_frame(
           state.native,
           buffer.payload,
           dts - base_dts,
           pts - base_dts,
           buffer.metadata.h264.key_frame?
         ) do
      {:ok, native} ->
        Map.put(state, :native, native)

      {:error, reason} ->
        raise "writing video frame failed with reason: #{inspect(reason)}"
    end
  end
end
