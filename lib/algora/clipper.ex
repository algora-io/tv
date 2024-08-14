defmodule Algora.Clipper do
  alias Algora.{Storage, Library}

  defp bucket(), do: Algora.config([:buckets, :media])

  def to_absolute(:video, uuid, uri),
    do: "#{Storage.endpoint_url()}/#{bucket()}/#{uuid}/#{uri}"

  def to_absolute(:clip, uuid, uri),
    do: "#{Storage.endpoint_url()}/#{bucket()}/clips/#{uuid}/#{uri}"

  def clip(video, from, to) do
    playlists = Algora.Admin.get_media_playlists(video)

    %{timeline: timeline, ss: ss} =
      playlists.video.timeline
      |> Enum.reduce(%{elapsed: 0, ss: 0, timeline: []}, fn x, acc ->
        case x do
          %ExM3U8.Tags.MediaInit{uri: uri} ->
            %{
              acc
              | timeline: [
                  %ExM3U8.Tags.MediaInit{uri: to_absolute(:video, video.uuid, uri)} | acc.timeline
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
                    uri: to_absolute(:video, video.uuid, uri)
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
                    uri: to_absolute(:video, video.uuid, uri)
                  }
                  | acc.timeline
                ]
            }

          _ ->
            acc
        end
      end)
      |> then(fn clip -> %{ss: clip.ss, timeline: Enum.reverse(clip.timeline)} end)

    %{playlist: %{playlists.video | timeline: timeline}, ss: ss}
  end

  def create_clip(video, from, to) do
    uuid = Ecto.UUID.generate()

    %{playlist: playlist, ss: ss} = clip(video, from, to)

    manifest = "#{ExM3U8.serialize(playlist)}#EXT-X-ENDLIST\n"

    {:ok, _} =
      Storage.upload(manifest, "clips/#{uuid}/g3cFdmlkZW8.m3u8",
        content_type: "application/x-mpegURL"
      )

    {:ok, _} =
      ExAws.S3.put_object_copy(
        bucket(),
        "clips/#{uuid}/index.m3u8",
        bucket(),
        "#{video.uuid}/index.m3u8"
      )
      |> ExAws.request()

    url = to_absolute(:clip, uuid, "index.m3u8")
    filename = Slug.slugify("#{video.title}-#{Library.to_hhmmss(from)}-#{Library.to_hhmmss(to)}")

    "ffmpeg -i \"#{url}\" -ss #{ss} -t #{to - from} \"#{filename}.mp4\""
  end
end
