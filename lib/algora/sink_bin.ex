defmodule Algora.SinkBin do
  @moduledoc """
  Bin responsible for receiving audio and video streams, performing payloading and CMAF muxing
  to eventually store them using provided storage configuration.

  ## Input streams
  Parsed H264 or AAC video or audio streams are expected to be connected via the `:input` pad.
  The type of stream has to be specified via the pad's `:encoding` option.

  ## Output
  Specify one of `Membrane.HTTPAdaptiveStream.Storages` as `:storage` to configure the sink.
  """
  use Membrane.Bin

  alias Membrane.{AAC, H264, MP4, Time}
  alias Membrane.HTTPAdaptiveStream.{Manifest, Storage}
  alias Algora.Sink

  def_options(
    manifest_name: [
      spec: String.t(),
      default: "index",
      description: "Name of the main manifest file"
    ],
    manifest_module: [
      spec: module,
      description: """
      Implementation of the `Membrane.HTTPAdaptiveStream.Manifest`
      behaviour.
      """
    ],
    storage: [
      spec: Storage.config_t(),
      description: """
      Storage configuration. May be one of `Membrane.HTTPAdaptiveStream.Storages.*`.
      See `Membrane.HTTPAdaptiveStream.Storage` behaviour.
      """
    ],
    target_window_duration: [
      spec: Time.t() | :infinity,
      default: Time.seconds(40),
      inspector: &Time.inspect/1,
      description: """
      Manifest duration is kept above that time, while the oldest segments
      are removed whenever possible.
      """
    ],
    persist?: [
      spec: boolean,
      default: false,
      description: """
      If true, stale segments are removed from the manifest only. Once
      playback finishes, they are put back into the manifest.
      """
    ],
    mode: [
      spec: :live | :vod,
      default: :vod,
      description: """
      Tells if the session is live or a VOD type of broadcast. It can influence type of metadata
      inserted into the playlist's manifest.
      """
    ],
    hls_mode: [
      spec: :muxed_av | :separate_av,
      default: :separate_av,
      description: """
      Option defining how the incoming tracks will be handled and how CMAF will be muxed.

      - In `:muxed_av` audio will be added to each video rendition, creating CMAF segments that contain both audio and video.
      - In `:separate_av` audio and video tracks will be separate and synchronization will need to be sorted out by the player.
      """
    ],
    header_naming_fun: [
      spec: (Manifest.Track.t(), counter :: non_neg_integer() -> String.t()),
      default: &Manifest.Track.default_header_naming_fun/2,
      description: "A function that generates consequent media header names for a given track"
    ],
    segment_naming_fun: [
      spec: (Manifest.Track.t() -> String.t()),
      default: &Manifest.Track.default_segment_naming_fun/1,
      description: "A function that generates consequent segment names for a given track"
    ],
    mp4_parameters_in_band?: [
      spec: boolean(),
      default: false,
      description: """
      Determines whether the parameter type nalus will be removed from the stream.
      Inband parameters seem to be legal with MP4, but some players don't respond kindly to them, so use at your own risk.
      This parameter should be set to true when discontinuity can occur. For example when resolution can change.
      """
    ],
    cleanup_after: [
      spec: nil | Time.t(),
      default: nil,
      description: """
      Time after which a fire-and-forget storage cleanup function should run.

      The function will remove all manifests and segments stored during the stream.
      """
    ]
  )

  def_input_pad(:input,
    accepted_format:
      any_of(
        Membrane.AAC,
        Membrane.H264
      ),
    availability: :on_request,
    options: [
      encoding: [
        spec: :AAC | :H264,
        description: """
        Encoding type determining which parser will be used for the given stream.
        """
      ],
      track_name: [
        spec: String.t() | nil,
        default: nil,
        description: """
        Name that will be used to name the media playlist for the given track, as well as its header and segments files.
        It must not contain any URI reserved characters
        """
      ],
      segment_duration: [
        spec: Membrane.Time.t(),
        description: """
        The minimal segment duration of the regular segments.
        """
      ],
      partial_segment_duration: [
        spec: Membrane.Time.t() | nil,
        default: nil,
        description: """
        The segment duration of the partial segments.
        If not set then the bin won't produce any partial segments.
        """
      ],
      max_framerate: [
        spec: float() | nil,
        default: nil,
        description: """
        The maximal framerate of video variant. This information is used in master playlist.

        When set to nil then this information won't be added to master playlist. For audio it should be set to nil.
        """
      ]
    ]
  )

  @impl true
  def handle_init(_ctx, opts) do
    structure = [
      child(:sink, %Sink{
        manifest_config: %Sink.ManifestConfig{
          name: opts.manifest_name,
          module: opts.manifest_module
        },
        track_config: %Sink.TrackConfig{
          target_window_duration: opts.target_window_duration,
          persist?: opts.persist?,
          header_naming_fun: opts.header_naming_fun,
          segment_naming_fun: opts.segment_naming_fun,
          mode: opts.mode
        },
        storage: opts.storage,
        cleanup_after: opts.cleanup_after
      })
    ]

    state = %{
      mode: opts.hls_mode,
      streams_to_start: 0,
      streams_to_end: 0,
      mp4_parameters_in_band?: opts.mp4_parameters_in_band?
    }

    {[spec: structure], state}
  end

  @impl true
  def handle_pad_added(pad, ctx, state) do
    do_handle_pad_added(pad, ctx.pad_options, ctx, state)
  end

  defp do_handle_pad_added(pad, pad_options, ctx, state)

  defp do_handle_pad_added(pad, pad_options, ctx, %{mode: :separate_av} = state) do
    Pad.ref(:input, ref) = pad

    spec =
      bin_input(pad)
      |> child({:parser, ref}, get_parser(pad_options.encoding, state))
      |> child({:cmaf_muxer, ref}, cmaf_child_definiton(pad_options))
      |> via_in(pad, options: track_options(ctx))
      |> get_child(:sink)

    state = increment_streams_counters(state)
    {[spec: spec], state}
  end

  defp do_handle_pad_added(pad, %{encoding: :H264} = pad_options, ctx, %{mode: :muxed_av} = state)
       when is_map_key(ctx.children, :audio_tee) do
    Pad.ref(:input, ref) = pad
    parser = get_parser(:H264, state)
    muxer = cmaf_child_definiton(pad_options)

    spec = [
      bin_input(pad)
      |> child({:parser, ref}, parser)
      |> child({:cmaf_muxer, ref}, muxer)
      |> via_in(pad, options: track_options(ctx))
      |> get_child(:sink),
      get_child(:audio_tee)
      |> get_child({:cmaf_muxer, ref})
    ]

    state = increment_streams_counters(state)
    {[spec: spec], state}
  end

  defp do_handle_pad_added(_pad, %{encoding: :H264}, _ctx, %{mode: :muxed_av} = state) do
    state = increment_streams_counters(state)
    {[], state}
  end

  defp do_handle_pad_added(pad, %{encoding: :AAC} = pad_options, ctx, %{mode: :muxed_av} = state) do
    if count_audio_tracks(ctx) > 1,
      do: raise("In :muxed_av mode, only one audio input is accepted")

    postponed_cmaf_muxers =
      Map.values(ctx.pads)
      |> Enum.filter(&(&1.direction == :input and &1.options[:encoding] == :H264))
      |> Enum.map(fn pad_data ->
        Pad.ref(:input, cmaf_ref) = pad_data.ref
        muxer = cmaf_child_definiton(pad_options)

        get_child(:audio_tee)
        |> child({:cmaf_muxer, cmaf_ref}, muxer)
      end)

    Pad.ref(:input, ref) = pad
    parser = get_parser(:AAC, state)

    spec =
      [
        bin_input(pad)
        |> child({:parser, ref}, parser)
        |> child(:audio_tee, Membrane.Tee.Parallel)
      ] ++ postponed_cmaf_muxers

    {[spec: spec], state}
  end

  defp cmaf_child_definiton(pad_options) do
    %MP4.Muxer.CMAF{
      segment_min_duration: pad_options.segment_duration,
      chunk_target_duration: pad_options.partial_segment_duration
    }
  end

  defp increment_streams_counters(state) do
    state
    |> Map.update!(:streams_to_start, &(&1 + 1))
    |> Map.update!(:streams_to_end, &(&1 + 1))
  end

  @impl true
  def handle_pad_removed(Pad.ref(:input, ref), ctx, state) do
    children =
      ([
         {:parser, ref}
       ] ++ if(state.mode != :muxed_av, do: [{:cmaf_muxer, ref}], else: []))
      |> Enum.filter(fn child_name ->
        child_entry = Map.get(ctx.children, child_name)
        child_entry != nil and !child_entry.terminating?
      end)

    {[remove_children: children], state}
  end

  @impl true
  def handle_element_start_of_stream(
        :sink,
        _pad,
        _ctx,
        %{streams_to_start: 1} = state
      ) do
    {[notify_parent: :start_of_stream], %{state | streams_to_start: 0}}
  end

  @impl true
  def handle_element_start_of_stream(:sink, _pad, _ctx, state) do
    {[], Map.update!(state, :streams_to_start, &(&1 - 1))}
  end

  @impl true
  def handle_element_start_of_stream(_element, _pad, _ctx, state) do
    {[], state}
  end

  @impl true
  def handle_element_end_of_stream(:sink, _pad, _ctx, %{streams_to_end: 1} = state) do
    {[notify_parent: :end_of_stream], %{state | streams_to_end: 0}}
  end

  @impl true
  def handle_element_end_of_stream(:sink, _pad, _ctx, state) do
    {[], Map.update!(state, :streams_to_end, &(&1 - 1))}
  end

  @impl true
  def handle_element_end_of_stream(_element, _pad, _ctx, state) do
    {[], state}
  end

  @impl true
  def handle_child_notification(
        {:track_playable, track_info},
        :sink,
        _ctx,
        state
      ) do
    # notify about playable just when track becomes available
    {[notify_parent: {:track_playable, track_info}], state}
  end

  defp track_options(context) do
    context.pad_options
    |> Map.take([:track_name, :segment_duration, :partial_segment_duration, :max_framerate])
    |> Keyword.new()
  end

  defp count_audio_tracks(context),
    do:
      Enum.count(context.pads, fn {_pad, metadata} ->
        metadata.options.encoding == :AAC
      end)

  defp get_parser(encoding, state) do
    if encoding == :AAC,
      do: %AAC.Parser{output_config: :esds, out_encapsulation: :none},
      else: %H264.Parser{
        output_stream_structure: if(state.mp4_parameters_in_band?, do: :avc3, else: :avc1)
      }
  end
end
