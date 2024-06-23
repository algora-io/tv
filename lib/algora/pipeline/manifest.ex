defmodule Algora.Pipeline.Manifest do
  @moduledoc """
  Behaviour for manifest serialization.
  """
  use Bunch.Access

  alias Membrane.HTTPAdaptiveStream.Manifest.{Changeset, Track}

  @type serialized_manifest_t :: {manifest_name :: String.t(), manifest_content :: String.t()}

  @type serialized_manifests_t :: %{
          master_manifest: serialized_manifest_t(),
          manifest_per_track: %{
            optional(track_id :: any()) => serialized_manifest_t()
          }
        }

  @callback serialize(t) :: serialized_manifests_t()

  @type t :: %__MODULE__{
          video_uuid: String.t(),
          name: String.t(),
          module: module,
          tracks: %{(id :: any) => Track.t()}
        }

  @enforce_keys [:video_uuid, :name, :module]
  defstruct @enforce_keys ++ [tracks: %{}]

  @doc """
  Add a track to the manifest.

  Returns the name under which the header file should be stored.
  """
  @spec add_track(t, Track.Config.t()) :: {header_name :: String.t(), t}
  def add_track(manifest, %Track.Config{} = config) do
    track = Track.new(config)
    manifest = %__MODULE__{manifest | tracks: Map.put(manifest.tracks, config.id, track)}
    {track.header_name, manifest}
  end

  @doc """
  Adds segment to the manifest. In case of ll-hls it will add partial segment, and also full segment if needed.
  Returns `Membrane.HTTPAdaptiveStream.Manifest.Track.Changeset`.
  """
  @spec add_chunk(
          t,
          track_id :: Track.id_t(),
          Membrane.Buffer.t()
        ) ::
          {Changeset.t(), t}
  def add_chunk(%__MODULE__{} = manifest, track_id, buffer) do
    opts = %{
      payload: buffer.payload,
      size: byte_size(buffer.payload),
      independent?: Map.get(buffer.metadata, :independent?, true),
      last_chunk?: Map.fetch!(buffer.metadata, :last_chunk?),
      duration: buffer.metadata.duration,
      complete?: true
    }

    get_and_update_in(
      manifest,
      [:tracks, track_id],
      &Track.add_chunk(&1, opts)
    )
  end

  @spec serialize(t) :: serialized_manifests_t()
  def serialize(%__MODULE__{module: module} = manifest) do
    module.serialize(manifest)
  end

  @spec has_track?(t(), Track.id_t()) :: boolean()
  def has_track?(%__MODULE__{tracks: tracks}, track_id), do: Map.has_key?(tracks, track_id)

  @spec persisted?(t(), Track.id_t()) :: boolean()
  def persisted?(%__MODULE__{tracks: tracks}, track_id),
    do: Track.persisted?(Map.get(tracks, track_id))

  @doc """
  Append a discontinuity to the track.

  This will inform the player that eg. the parameters of the encoder changed and allow you to provide a new MP4 header.
  For details on discontinuities refer to [RFC 8216](https://datatracker.ietf.org/doc/html/rfc8216).
  """
  @spec discontinue_track(t(), Track.id_t()) :: {header_name :: String.t(), t()}
  def discontinue_track(%__MODULE__{} = manifest, track_id) do
    get_and_update_in(
      manifest,
      [:tracks, track_id],
      &Track.discontinue/1
    )
  end

  @spec finish(t, Track.id_t()) :: {Changeset.t(), t}
  def finish(%__MODULE__{} = manifest, track_id) do
    get_and_update_in(manifest, [:tracks, track_id], &Track.finish/1)
  end

  @doc """
  Filter all tracks that have option `:persisted?` set to true, then
  restores all the stale segments in those tracks.
  """
  @spec from_beginning(t()) :: t
  def from_beginning(%__MODULE__{} = manifest) do
    tracks =
      manifest.tracks
      |> Enum.filter(fn {_track_id, track} -> Track.persisted?(track) end)
      |> Map.new(fn {track_id, track} -> {track_id, Track.from_beginning(track)} end)

    %__MODULE__{manifest | tracks: tracks}
  end

  @doc """
  Returns all segments grouped by the track id.
  """
  @spec segments_per_track(t()) :: %{
          optional(track_id :: term()) => [segment_name :: String.t()]
        }
  def segments_per_track(%__MODULE__{} = manifest) do
    Map.new(manifest.tracks, fn {track_id, track} -> {track_id, Track.all_segments(track)} end)
  end

  @doc """
  Returns one header per track
  """
  @spec header_per_track(t()) :: %{optional(track_id :: term()) => String.t()}
  def header_per_track(%__MODULE__{} = manifest) do
    Map.new(manifest.tracks, fn {track_id, track} -> {track_id, Track.header(track)} end)
  end
end
