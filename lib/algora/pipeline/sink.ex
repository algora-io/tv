defmodule Algora.Pipeline.Sink do
  @moduledoc """
  Sink for generating HTTP streaming manifests.

  Uses `Algora.Pipeline.Manifest` for manifest serialization
  and `Membrane.HTTPAdaptiveStream.Storage` for saving files.

  ## Notifications

  - `{:track_playable, input_pad_id}` - sent when the first segment of a track is
    stored, and thus the track is ready to be played

  ## Examples

  The following configuration:

  %#{inspect(__MODULE__)}{
        manifest_config: %ManifestConfig{name: "manifest", module: Membrane.HTTPAdaptiveStream.HLS}
        storage: %Membrane.HTTPAdaptiveStream.Storages.FileStorage{directory: "output"}
      }

  will generate a HLS manifest in the `output` directory, playable from
  `output/manifest.m3u8` file.
  """

  use Membrane.Sink

  require Membrane.HTTPAdaptiveStream.Manifest.SegmentAttribute

  alias Membrane.CMAF
  alias Algora.Pipeline.Manifest
  alias Membrane.HTTPAdaptiveStream.Manifest.Track
  alias Membrane.HTTPAdaptiveStream.Storage

  defmodule TrackConfig do
    @moduledoc """
    Track configuration. For more information checkout `Membrane.HTTPAdaptiveStream.Manifest.Track.Config`
    """
    @type t :: %__MODULE__{
            target_window_duration: Membrane.Time.t() | :infinity,
            mode: :live | :vod,
            header_naming_fun: (Track.t(), counter :: non_neg_integer -> String.t()),
            segment_naming_fun: (Track.t() -> String.t()),
            partial_naming_fun: (String.t(), Keyword.t() -> String.t()),
            persist?: boolean()
          }

    defstruct target_window_duration: Membrane.Time.seconds(40),
              mode: :vod,
              header_naming_fun: &Track.default_header_naming_fun/2,
              segment_naming_fun: &Track.default_segment_naming_fun/1,
              partial_naming_fun: &Track.default_partial_naming_fun/2,
              persist?: false
  end

  defmodule ManifestConfig do
    @moduledoc """
    `Algora.Pipeline.Manifest` configuration.
    """

    @typedoc """
    Manifest configuration consists of the following fields:
    - `name` - name of the main manifest file.
    - `module` - implementation of the `Algora.Pipeline.Manifest` behaviour.
    """
    @type t() :: %__MODULE__{
            video_uuid: String.t(),
            name: String.t(),
            module: module()
          }

    @enforce_keys [:video_uuid, :module]
    defstruct @enforce_keys ++ [name: "index"]
  end

  def_input_pad(:input,
    availability: :on_request,
    flow_control: :manual,
    demand_unit: :buffers,
    accepted_format: CMAF.Track,
    options: [
      track_name: [
        spec: String.t() | nil,
        default: nil,
        description: """
        Name that will be used to name the media playlist for the given track, as well as its header and segments files.
        It must not contain any URI reserved characters.
        """
      ],
      segment_duration: [
        spec: Membrane.Time.t(),
        description: """
        The minimal duration of media segments produced by this particular track.

        In case of regular paced streams the parameter may not have any impact, but when
        partial segments gets used it may decide when regular segments gets finalized and new gets started.
        """
      ],
      partial_segment_duration: [
        spec: Membrane.Time.t() | nil,
        default: nil,
        description: """
        The target duration of partial segments.

        When set to nil then the track is not supposed to emit partial segments.
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

  def_options(
    manifest_config: [
      spec: ManifestConfig.t(),
      description: """
      """
    ],
    track_config: [
      spec: TrackConfig.t(),
      description: """
      """
    ],
    storage: [
      spec: Storage.config_t(),
      description: """
      Storage configuration. May be one of `Membrane.HTTPAdaptiveStream.Storages.*`.
      See `Membrane.HTTPAdaptiveStream.Storage` behaviour.
      """
    ],
    cleanup_after: [
      spec: nil | Membrane.Time.t(),
      default: nil,
      description: """
      If not `nil`, time after a storage cleanup function should run.

      The function will remove all manifests and segments stored during the stream.
      """
    ]
  )

  @impl true
  def handle_init(_ctx, options) do
    state =
      options
      |> Map.from_struct()
      |> Map.merge(%{
        storage: Storage.new(options.storage),
        manifest: %Manifest{
          video_uuid: options.manifest_config.video_uuid,
          name: options.manifest_config.name,
          module: options.manifest_config.module
        },
        playlist_playable_sent: MapSet.new()
      })

    {[], state}
  end

  def handle_parent_notification(:disconnected, _ctx, state) do
    %{
      manifest: manifest,
      storage: storage,
    } = state

    tracks = Enum.map(manifest.tracks, fn {track_name, track} ->
      naming_fun = fn(track, _counter) ->
        # TODO why is the actual header not uploading?
        name = Enum.join([track.content_type, "header", track.track_name, "part", "0"], "_")
        Algora.Storage.to_absolute(:video, manifest.video_uuid, name)
      end

      track = %{ track | header_naming_fun: naming_fun}
      {_header_name, track} = Track.discontinue(track)
      {track_name, track}
    end) |> Map.new()

    manifest = Map.put(manifest, :tracks, tracks)
    case serialize_and_store_manifest(manifest, storage) do
      {:ok, storage} ->
        {[], %{state | manifest: manifest, storage: storage }}
      {:error, reason} ->
        raise "Failed to resume the manifest due to #{inspect(reason)}"
    end
  end

  def handle_parent_notification(:reconnected, _ctx, state) do
    {[], state}
  end

  @impl true
  def handle_stream_format(
        Pad.ref(:input, track_id) = pad_ref,
        %CMAF.Track{} = stream_format,
        ctx,
        state
      ) do
    {header_name, manifest} =
      if Manifest.has_track?(state.manifest, track_id) do
        # Arrival of new stream format for an already existing track indicate that stream parameters have changed.
        # According to section 4.3.2.3 of RFC 8216, discontinuity needs to be signaled and new header supplied.
        Manifest.discontinue_track(state.manifest, track_id)
      else
        track_options = ctx.pads[pad_ref].options
        track_name = serialize_track_name(track_options[:track_name] || track_id)

        track_config_params =
          state.track_config
          |> Map.from_struct()
          |> Map.merge(%{
            id: track_id,
            track_name: track_name,
            content_type: stream_format.content_type,
            header_extension: ".mp4",
            segment_extension: ".m4s",
            segment_duration: track_options.segment_duration,
            partial_segment_duration: track_options.partial_segment_duration,
            encoding: stream_format.codecs,
            resolution: stream_format.resolution,
            max_framerate: track_options.max_framerate
          })

        track_config = struct!(Track.Config, track_config_params)

        Manifest.add_track(
          state.manifest,
          track_config
        )
      end

    case Storage.store_header(state.storage, track_id, header_name, stream_format.header) do
      {:ok, storage} ->
        {[], %{state | storage: storage, manifest: manifest}}

      {{:error, reason}, _storage} ->
        raise "Failed to store the header for track #{inspect(track_id)} due to #{inspect(reason)}"
    end
  end

  @impl true
  def handle_playing(ctx, state) do
    demands = ctx.pads |> Map.keys() |> Enum.map(&{:demand, &1})
    {demands, state}
  end

  @impl true
  def handle_pad_added(pad, %{playback: :playing}, state), do: {[demand: pad], state}

  @impl true
  def handle_pad_added(_pad, _ctx, state), do: {[], state}

  @impl true
  def handle_buffer(Pad.ref(:input, track_id) = pad, buffer, _ctx, %{storage: storage} = state) do
    {changeset, manifest} = Manifest.add_chunk(state.manifest, track_id, buffer)

    with {:ok, storage} <- Storage.apply_track_changeset(storage, track_id, changeset),
         {:ok, storage} <- serialize_and_store_manifest(manifest, storage) do
      {notify, state} = maybe_notify_playable(track_id, state)
      {notify ++ [demand: pad], %{state | manifest: manifest, storage: storage}}
    else
      {{:error, reason}, _storage} ->
        raise "Failed to store a buffer for track #{inspect(track_id)} due to #{inspect(reason)}"
    end
  end

  @impl true
  def handle_end_of_stream(
        Pad.ref(:input, track_id),
        _ctx,
        %{manifest: manifest, storage: storage} = state
      ) do
    {changeset, manifest} = Manifest.finish(manifest, track_id)

    with {:ok, storage} <- Storage.apply_track_changeset(storage, track_id, changeset),
         {:ok, storage} <- serialize_and_store_manifest(manifest, storage) do
      storage = Storage.clear_cache(storage)
      {[], %{state | storage: storage, manifest: manifest}}
    else
      {{:error, reason}, _storage} ->
        raise "Failed to store the finalized manifest for track #{inspect(track_id)} due to #{inspect(reason)}"
    end
  end

  @impl true
  def handle_terminate_request(ctx, state) do
    %{
      manifest: manifest,
      storage: storage
    } = state

    track_ids =
      ctx.pads
      |> Map.keys()
      |> Enum.map(fn
        Pad.ref(:input, track_id) -> track_id
      end)

    # prevent storing empty manifest, such situation can happen
    # when the sink goes from prepared -> playing -> prepared -> stopped
    # and in the meantime no media has flown through input pads
    any_track_persisted? =
      Enum.any?(track_ids, fn track_id ->
        Manifest.has_track?(manifest, track_id) and Manifest.persisted?(manifest, track_id)
      end)

    result =
      if any_track_persisted? do
        # reconfigure tracks to disable partial segments on final manifest
        tracks = Enum.reduce(manifest.tracks, %{}, fn({name, track}, acc) ->
          Map.put(acc, name, %Track{ track | mode: :vod, partial_segment_duration: nil })
        end)

        {result, storage} =
          manifest
          |> Map.put(:tracks, tracks)
          |> Manifest.from_beginning()
          |> serialize_and_store_manifest(storage)

        {result, %{state | storage: storage}}
      else
        {:ok, state}
      end

    case result do
      {:ok, state} ->
        :ok = maybe_schedule_cleanup_task(state)

        {[terminate: :normal], state}

      {{:error, reason}, _state} ->
        raise "Failed to persist the manifest due to #{inspect(reason)}"
    end
  end

  defp serialize_track_name(track_id) when is_binary(track_id) do
    valid_filename_regex = ~r/^[^\/:*?"<>|]+$/

    if String.match?(track_id, valid_filename_regex) do
      track_id
    else
      raise "The provided track identifier #{inspect(track_id)} is not a valid filename"
    end
  end

  defp serialize_track_name(track_id) do
    track_id |> :erlang.term_to_binary() |> Base.url_encode64(padding: false)
  end

  defp maybe_notify_playable(track_id, %{playlist_playable_sent: playlist_playable_sent} = state) do
    if MapSet.member?(playlist_playable_sent, track_id) do
      {[notify_parent: {:track_activity, track_id}], state}
    else
      {[notify_parent: {:track_playable, track_id}],
       %{state | playlist_playable_sent: MapSet.put(playlist_playable_sent, track_id)}}
    end
  end

  defp serialize_and_store_manifest(manifest, storage) do
    serialized_manifest = Manifest.serialize(manifest)
    Storage.store_manifests(storage, serialized_manifest)
  end

  defp maybe_schedule_cleanup_task(%{cleanup_after: nil}), do: :ok

  defp maybe_schedule_cleanup_task(%{
         manifest: manifest,
         storage: storage,
         cleanup_after: cleanup_after
       }) do
    {:ok, _pid} =
      Task.start(fn ->
        segments_to_remove = Manifest.segments_per_track(manifest)
        headers_to_remove = Manifest.header_per_track(manifest)

        timeout = Membrane.Time.as_milliseconds(cleanup_after, :round)

        Process.sleep(timeout)

        # cleanup all data of the secondary playlist and the master one
        with {:ok, storage} <-
               Storage.clean_all_tracks(storage, segments_to_remove, headers_to_remove),
             {:ok, _storage} <- Storage.cleanup(storage, :master, [], nil) do
          :ok
        else
          {{:error, reason}, _storage} ->
            raise "Failed to cleanup the storage due to #{inspect(reason)}"
        end
      end)

    :ok
  end

end
