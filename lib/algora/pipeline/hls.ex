defmodule Algora.Pipeline.HLS do
  @moduledoc false

  @behaviour Algora.Pipeline.Manifest

  use Numbers, overload_operators: true

  alias Algora.Pipeline.Manifest
  alias Membrane.HTTPAdaptiveStream.BandwidthCalculator
  alias Membrane.HTTPAdaptiveStream.Manifest.{Segment, Track}
  alias Membrane.Time

  @version 7
  @delta_version 9

  @master_playlist_header """
                          #EXTM3U
                          #EXT-X-VERSION:#{@version}
                          #EXT-X-INDEPENDENT-SEGMENTS
                          """
                          |> String.trim()

  @empty_segments Qex.new()
  @default_audio_track_id "audio_default_id"
  @default_audio_track_name "audio_default_name"

  @keep_latest_n_segment_parts 4
  @min_segments_in_delta_playlist 6

  defmodule SegmentAttribute do
    @moduledoc """
    Implementation of `Membrane.HTTPAdaptiveStream.Manifest.SegmentAttribute` behaviour for HTTP Live Streaming
    """
    @behaviour Membrane.HTTPAdaptiveStream.Manifest.SegmentAttribute

    import Membrane.HTTPAdaptiveStream.Manifest.SegmentAttribute

    @impl true
    def serialize(discontinuity(header_name, number)) do
      [
        "#EXT-X-DISCONTINUITY-SEQUENCE:#{number}",
        "#EXT-X-DISCONTINUITY",
        "#EXT-X-MAP:URI=\"#{header_name}\""
      ]
    end

    @impl true
    def serialize({:creation_time, date_time}) do
      [
        "#EXT-X-PROGRAM-DATE-TIME:#{date_time |> DateTime.truncate(:millisecond) |> DateTime.to_iso8601()}"
      ]
    end

    def serialize(discontinuity(header_name, number), base_url) do
      [
        "#EXT-X-DISCONTINUITY-SEQUENCE:#{number}",
        "#EXT-X-DISCONTINUITY",
        "#EXT-X-MAP:URI=\"#{base_url}/#{header_name}\""
      ]
    end

    def serialize({:creation_time, _date_time} = msg, _base_url), do: serialize(msg)

  end

  @doc """
  Generates EXTM3U playlist for the given manifest
  """
  @impl true
  def serialize(%Manifest{} = manifest) do
    tracks_by_content =
      manifest.tracks
      |> Map.values()
      |> Enum.group_by(& &1.content_type)

    if length(Map.get(tracks_by_content, :audio, [])) > 1 do
      raise ArgumentError, message: "Multiple audio tracks are not currently supported."
    end

    master_manifest = master_playlist_from_tracks(tracks_by_content, manifest)
    manifest_per_track = playlists_per_track(manifest, tracks_by_content)

    %{
      master_manifest: master_manifest,
      manifest_per_track: manifest_per_track
    }
  end

  defp master_playlist_from_tracks(tracks, manifest) do
    master_manifest_name = "#{manifest.name}.m3u8"

    master_playlist =
      case tracks do
        %{muxed: muxed} -> build_master_playlist({nil, muxed})
        %{audio: [audio], video: videos} -> build_master_playlist({audio, videos})
        %{audio: [audio]} -> build_master_playlist({audio, nil})
        %{video: videos} -> build_master_playlist({nil, videos})
      end

    {master_manifest_name, master_playlist}
  end

  defp playlists_per_track(%Manifest{} = manifest, tracks) do
    case tracks do
      %{muxed: tracks} ->
        serialize_tracks(manifest, tracks)

      %{audio: audios, video: videos} ->
        serialized_videos = serialize_tracks(manifest, videos)
        serialized_audios = serialize_tracks(manifest, audios)
        Map.merge(serialized_videos, serialized_audios)

      %{audio: audios} ->
        serialize_tracks(manifest, audios)

      %{video: videos} ->
        serialize_tracks(manifest, videos)
    end
  end

  defp serialize_tracks(%Manifest{} = manifest, tracks) do
    tracks
    |> Enum.filter(&(&1.segments != @empty_segments))
    |> Enum.reduce(%{}, &add_serialized_track(manifest, &2, &1))
  end

  defp add_serialized_track(%Manifest{} = manifest, tracks_map, track) do
    target_duration = calculate_target_duration(track)
    playlist_path = build_media_playlist_path(track)

    case maybe_calculate_delta_params(track, target_duration) do
      {:create_delta, delta_ctx} ->
        serialized_track =
          {playlist_path,
           serialize_track(manifest, track, target_duration, %{delta_ctx | skip_count: 0})}

        delta_path = build_media_playlist_path(track, delta?: true)

        serialized_delta_track =
          {delta_path, serialize_track(manifest, track, target_duration, delta_ctx)}

        tracks_map
        |> Map.put(track.id, serialized_track)
        |> Map.put(:"#{track.id}_delta", serialized_delta_track)

      :dont_create_delta ->
        serialized_track = {playlist_path, serialize_track(manifest, track, target_duration)}
        Map.put(tracks_map, track.id, serialized_track)
    end
  end

  defp calculate_target_duration(track) do
    Ratio.ceil(track.segment_duration / Time.second()) |> trunc()
  end

  defp maybe_calculate_delta_params(track, target_duration) do
    min_duration = Time.seconds(@min_segments_in_delta_playlist * target_duration)
    segments = track.segments

    with true <- Track.supports_partial_segments?(track),
         true <- track_supports_delta_creation?(track),
         latest_full_segments <-
           segments
           |> Qex.reverse()
           |> Enum.drop_while(&(&1.type == :partial)),
         {skip_count, skip_duration} <-
           latest_full_segments
           |> Enum.with_index()
           |> Enum.reduce_while(0, fn {segment, idx}, duration ->
             duration = duration + segment.duration

             if duration >= min_duration,
               do: {:halt, {Enum.count(latest_full_segments) - idx - 1, duration}},
               else: {:cont, duration}
           end),
         true <- skip_count > 0 do
      delta_ctx = %{
        skip_count: skip_count,
        skip_duration: Ratio.to_float(skip_duration / Time.second())
      }

      {:create_delta, delta_ctx}
    else
      _any -> :dont_create_delta
    end
  end

  defp track_supports_delta_creation?(track) do
    track.target_window_duration == :infinity
  end

  defp build_media_playlist_path(track, opts \\ [delta?: false])

  defp build_media_playlist_path(%Track{} = track, delta?: true) do
    track.track_name <> "_delta.m3u8"
  end

  defp build_media_playlist_path(%Track{} = track, delta?: false) do
    track.track_name <> ".m3u8"
  end

  defp build_media_playlist_tag(%Track{} = track) do
    case track do
      %Track{content_type: :audio} ->
        """
        #EXT-X-MEDIA:TYPE=AUDIO,NAME="#{@default_audio_track_name}",GROUP-ID="#{@default_audio_track_id}",AUTOSELECT=YES,DEFAULT=YES,URI="#{build_media_playlist_path(track)}"#{serialize_encoding(track)}
        """
        |> String.trim()

      %Track{content_type: type} when type in [:video, :muxed] ->
        """
        #EXT-X-STREAM-INF:#{serialize_bandwidth(track)}#{serialize_resolution(track)}#{serialize_framerate(track)}#{serialize_encoding(track)}
        """
        |> String.trim()
    end
  end

  defp serialize_bandwidth(track) do
    "BANDWIDTH=#{BandwidthCalculator.calculate_max_bandwidth(track)},AVERAGE-BANDWIDTH=#{BandwidthCalculator.calculate_avg_bandwidth(track)}"
  end

  defp serialize_framerate(%Track{max_framerate: framerate}) when is_number(framerate),
    do: ",FRAME-RATE=#{framerate}"

  defp serialize_framerate(_track), do: ""

  defp serialize_resolution(%Track{resolution: {width, height}}) do
    ",RESOLUTION=#{width}x#{height}"
  end

  defp serialize_resolution(_track), do: ""

  defp serialize_encoding(%Track{encoding: %{} = encoding}) do
    codecs_string =
      encoding
      |> Enum.map_join(",", &serialize_codec(&1))
      |> String.trim()

    ",CODECS=\"#{codecs_string}\""
  end

  defp serialize_encoding(%Track{}), do: ""

  defp serialize_codec({:avc1, %{profile: profile, compatibility: compatibility, level: level}}) do
    [profile, compatibility, level]
    |> Enum.map(&Integer.to_string(&1, 16))
    |> Enum.map_join(&String.pad_leading(&1, 2, "0"))
    |> then(&"avc1.#{&1}")
    |> String.downcase()
  end

  defp serialize_codec({:mp4a, %{aot_id: aot_id}}), do: String.downcase("mp4a.40.#{aot_id}")

  defp serialize_codec(_other), do: ""

  defp build_master_playlist(tracks) do
    case tracks do
      {audio, nil} ->
        [@master_playlist_header, build_media_playlist_tag(audio)]
        |> Enum.join("")

      {nil, videos} ->
        [
          @master_playlist_header
          | videos
            |> Enum.filter(&(&1.segments != @empty_segments))
            |> Enum.flat_map(&[build_media_playlist_tag(&1), build_media_playlist_path(&1)])
        ]
        |> Enum.join("\n")

      {audio, videos} ->
        video_tracks =
          videos
          |> Enum.filter(&(&1.segments != @empty_segments))
          |> Enum.flat_map(
            &[
              "#{build_media_playlist_tag(&1)},AUDIO=\"#{@default_audio_track_id}\"",
              build_media_playlist_path(&1)
            ]
          )

        [
          @master_playlist_header,
          build_media_playlist_tag(audio),
          video_tracks
        ]
        |> List.flatten()
        |> Enum.join("\n")
    end
  end

  defp serialize_track(
         %Manifest{} = manifest,
         %Track{} = track,
         target_duration,
         delta_ctx \\ %{skip_count: 0, skip_duration: 0}
       ) do
    supports_ll_hls? = Track.supports_partial_segments?(track)

    """
    #EXTM3U
    #EXT-X-VERSION:#{if delta_ctx.skip_count > 0, do: @delta_version, else: @version}
    #EXT-X-TARGETDURATION:#{target_duration}
    """ <>
      serialize_ll_hls_tags(track, segments_to_skip_duration: delta_ctx.skip_duration) <>
      """
      #EXT-X-MEDIA-SEQUENCE:#{track.current_seq_num}
      #EXT-X-DISCONTINUITY-SEQUENCE:#{track.current_discontinuity_seq_num}
      #EXT-X-MAP:URI="#{storage_base_url()}/#{manifest.video_uuid}/#{track.header_name}"
      #{serialize_segments(manifest, track.segments, supports_ll_hls?: supports_ll_hls?, segments_to_skip_count: delta_ctx.skip_count)}
      #{if track.finished?, do: "#EXT-X-ENDLIST", else: serialize_preload_hint_tag(supports_ll_hls?, track)}
      """
  end

  defp serialize_segments(%Manifest{} = manifest, segments,
         supports_ll_hls?: supports_ll_hls?,
         segments_to_skip_count: segments_to_skip_count
       )
       when segments_to_skip_count > 0 do
    prefix = """
    #EXT-X-SKIP:SKIPPED-SEGMENTS=#{segments_to_skip_count}
    """

    serialized_segments =
      serialize_segments(manifest, Enum.drop(segments, segments_to_skip_count),
        supports_ll_hls?: supports_ll_hls?,
        segments_to_skip_count: 0
      )

    prefix <> serialized_segments
  end

  defp serialize_segments(%Manifest{} = manifest, segments,
         supports_ll_hls?: supports_ll_hls?,
         segments_to_skip_count: 0
       ) do
    segments
    |> Enum.split(-@keep_latest_n_segment_parts)
    |> then(fn {regular_segments, ll_segments} ->
      regular = Enum.flat_map(regular_segments, &do_serialize_segment(manifest, &1, false))
      ll = Enum.flat_map(ll_segments, &do_serialize_segment(manifest, &1, supports_ll_hls?))

      regular ++ ll
    end)
    |> Enum.join("\n")
  end

  defp do_serialize_segment(%Manifest{} = manifest, %Segment{} = segment, supports_ll_hls?) do
    [
      # serialize partial segments just for the last 4 live segments, otherwise just keep the regular segments
      if(supports_ll_hls?,
        do: serialize_partial_segments(segment),
        else: []
      ),
      serialize_regular_segment(manifest, segment)
    ]
    |> List.flatten()
  end

  defp serialize_regular_segment(%Manifest{} = _manifest, %Segment{type: :partial}), do: []

  defp serialize_regular_segment(%Manifest{} = manifest, segment) do
    time = Ratio.to_float(segment.duration / Time.second())

    Enum.flat_map(segment.attributes, &SegmentAttribute.serialize(&1, "#{storage_base_url()}/#{manifest.video_uuid}")) ++
      [
        "#EXTINF:#{time},",
        "#{storage_base_url()}/#{manifest.video_uuid}/#{segment.name}"
      ]
  end

  defp serialize_partial_segments(%Segment{} = segment) do
    Enum.map(segment.parts, fn part ->
      time = Ratio.to_float(part.duration / Time.second())

      serialized = "#EXT-X-PART:DURATION=#{time},URI=\"#{part.name}\""

      if part.independent?,
        do: serialized <> ",INDEPENDENT=YES",
        else: serialized
    end)
  end

  defp serialize_ll_hls_tags(track, segments_to_skip_duration: segments_to_skip_duration) do
    supports_ll_hls? = Track.supports_partial_segments?(track)

    if supports_ll_hls? do
      target_partial_duration =
        Float.ceil(Ratio.to_float(track.partial_segment_duration / Time.second()), 3)

      """
      #EXT-X-SERVER-CONTROL:CAN-BLOCK-RELOAD=YES,PART-HOLD-BACK=#{3 * target_partial_duration}#{can_skip_until(segments_to_skip_duration)}
      #EXT-X-PART-INF:PART-TARGET=#{target_partial_duration}
      """
    else
      ""
    end
  end

  defp serialize_preload_hint_tag(true, %Track{} = track) do
    if Enum.empty?(track.segments) do
      ""
    else
      name = track.partial_naming_fun.(track, preload_hint?: true)

      "#EXT-X-PRELOAD-HINT:TYPE=PART,URI=\"#{name}\""
    end
  end

  defp serialize_preload_hint_tag(false, _track), do: ""

  defp can_skip_until(duration) when duration > 0,
    do: ",CAN-SKIP-UNTIL=#{duration}"

  defp can_skip_until(_duration), do: ""

  defp storage_base_url do
    %{scheme: scheme, host: host} = Application.fetch_env!(:ex_aws, :s3) |> Enum.into(%{})
    "#{scheme}#{host}/#{Algora.config([:buckets, :media])}"
  end
end
