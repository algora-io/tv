defmodule Algora.Clipper do
  alias Algora.Storage

  defp bucket(), do: Algora.config([:buckets, :media])

  defp to_absolute(uuid, uri), do: "#{Storage.endpoint_url()}/#{bucket()}/#{uuid}/#{uri}"

  def clip(video, from, to) do
    playlists = Algora.Admin.get_media_playlists(video)

    timeline =
      playlists.video.timeline
      |> Enum.reduce(%{elapsed: 0, timeline: []}, fn x, acc ->
        case x do
          %ExM3U8.Tags.MediaInit{uri: uri} ->
            %{
              acc
              | timeline: [
                  %ExM3U8.Tags.MediaInit{uri: to_absolute(video.uuid, uri)} | acc.timeline
                ]
            }

          %ExM3U8.Tags.Segment{duration: duration} when acc.elapsed > to ->
            %{acc | elapsed: acc.elapsed + duration}

          %ExM3U8.Tags.Segment{duration: duration} when acc.elapsed + duration < from ->
            %{acc | elapsed: acc.elapsed + duration}

          %ExM3U8.Tags.Segment{duration: duration, uri: uri} ->
            %{
              acc
              | elapsed: acc.elapsed + duration,
                timeline: [
                  %ExM3U8.Tags.Segment{duration: duration, uri: to_absolute(video.uuid, uri)}
                  | acc.timeline
                ]
            }

          _ ->
            acc
        end
      end)
      |> then(fn clip -> Enum.reverse(clip.timeline) end)

    %{playlists.video | timeline: timeline}
  end

  def create_manifest(video, from, to) do
    "#{clip(video, from, to) |> ExM3U8.serialize()}#EXT-X-ENDLIST\n"
  end

  def create_clip(video, from, to) do
    uuid = Ecto.UUID.generate()

    manifest = create_manifest(video, from, to)

    {:ok, _} =
      Storage.upload(manifest, "#{uuid}/g3cFdmlkZW8.m3u8", content_type: "application/x-mpegURL")

    {:ok, _} =
      ExAws.S3.put_object_copy(
        bucket(),
        "#{uuid}/index.m3u8",
        bucket(),
        "#{video.uuid}/index.m3u8"
      )
      |> ExAws.request()

    timestamp = video.inserted_at |> NaiveDateTime.to_string() |> Slug.slugify()
    title = Slug.slugify(video.title)

    IO.puts(
      "ffmpeg -i \"#{to_absolute(uuid, "index.m3u8")}\" -c copy \"#{timestamp}-#{title}-#{from}-#{to}.mp4\""
    )
  end
end
