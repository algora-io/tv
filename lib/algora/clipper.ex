defmodule Algora.Clipper do
  alias Algora.{Storage, Library}

  def clip(video, from, to) do
    clip_timelines(video, from, to) |> List.first() |> elem(0)
  end

  def create_clip(video, from, to) do
    uuid = Ecto.UUID.generate()

    [{_manifet_name, %{ss: ss}}|_] = playlists = clip_timelines(video, from, to)

    Enum.each(playlists, fn({manifest_name, %{playlist: playlist, ss: ss}}) ->
      manifest = "#{ExM3U8.serialize(playlist)}#EXT-X-ENDLIST\n"

      {:ok, _} =
        Storage.upload(manifest, "clips/#{uuid}/#{manifest_name}",
          content_type: "application/x-mpegURL"
        )
    end)

    {:ok, _} =
      ExAws.S3.put_object_copy(
        Storage.bucket(),
        "clips/#{uuid}/index.m3u8",
        Storage.bucket(),
        "#{video.uuid}/index.m3u8"
      )
      |> ExAws.request()

    url = Storage.to_absolute(:clip, uuid, "index.m3u8")
    filename = Slug.slugify("#{video.title}-#{Library.to_hhmmss(from)}-#{Library.to_hhmmss(to)}")

    "ffmpeg -i \"#{url}\" -ss #{ss} -t #{to - from} \"#{filename}.mp4\""
  end

  def clip_timelines(video, from, to) do
    playlists = Algora.Admin.get_media_playlists(video)
    Enum.map(playlists, fn({manifest_name, playlist}) ->
      {manifest_name, clip_timeline(video, playlist, from, to)}
    end)
  end

  def clip_timeline(video, playlist, from, to) do
    %{timeline: timeline, ss: ss} =
      playlist.timeline
      |> Enum.reduce(%{elapsed: 0, ss: 0, timeline: []}, fn x, acc ->
        case x do
          %ExM3U8.Tags.MediaInit{uri: uri} ->
            %{
              acc
              | timeline: [
                  %ExM3U8.Tags.MediaInit{uri: Storage.to_absolute(:video, video.uuid, uri)} | acc.timeline
                ]
            }

          %ExM3U8.Tags.Segment{duration: duration} when acc.elapsed > to ->
            %{acc | elapsed: acc.elapsed + duration}

          %ExM3U8.Tags.Segment{duration: duration} when acc.elapsed + duration < from ->
            %{acc | elapsed: acc.elapsed + duration}

          %ExM3U8.Tags.Segment{duration: duration, uri: uri}
          when acc.elapsed < from and acc.elapsed + duration > from ->
            %{
              acc
              | elapsed: acc.elapsed + duration,
                ss: acc.elapsed + duration - from,
                timeline: [
                  %ExM3U8.Tags.Segment{
                    duration: duration,
                    uri: Storage.to_absolute(:video, video.uuid, uri)
                  }
                  | acc.timeline
                ]
            }

          %ExM3U8.Tags.Segment{duration: duration, uri: uri} ->
            %{
              acc
              | elapsed: acc.elapsed + duration,
                timeline: [
                  %ExM3U8.Tags.Segment{
                    duration: duration,
                    uri: Storage.to_absolute(:video, video.uuid, uri)
                  }
                  | acc.timeline
                ]
            }

          _ ->
            acc
        end
      end)
      |> then(fn clip -> %{ss: clip.ss, timeline: Enum.reverse(clip.timeline)} end)

    %{playlist: %{playlist | timeline: timeline}, ss: ss}
  end

end
