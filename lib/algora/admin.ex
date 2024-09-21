import Ecto.Query, warn: false
import Ecto.Changeset
alias Algora.{Accounts, Library, Storage, Repo}
alias Algora.Library.Video

defmodule Algora.Admin do
  @tracks %{
    manifest: "index.m3u8",
    audio: "g3cFYXVkaW8.m3u8",
    video: "g3cFdmlkZW8.m3u8"
  }

  def whoami(), do: {System.get_env("FLY_REGION"), Node.self()}

  defp get(url) do
    Finch.build(:get, url) |> Finch.request(Algora.Finch)
  end

  defp get_absolute_media_playlist(video) do
    %ExM3U8.MediaPlaylist{timeline: timeline, info: info} =
      get_media_playlist(video, @tracks.video)

    timeline =
      timeline
      |> Enum.reduce([], fn x, acc ->
        case x do
          %ExM3U8.Tags.MediaInit{uri: uri} ->
            [
              %ExM3U8.Tags.MediaInit{uri: Storage.to_absolute(:video, video.uuid, uri)}
              | acc
            ]

          %ExM3U8.Tags.Segment{uri: uri, duration: duration} ->
            [
              %ExM3U8.Tags.Segment{
                uri: Storage.to_absolute(:video, video.uuid, uri),
                duration: duration
              }
              | acc
            ]

          others ->
            [others | acc]
        end
      end)
      |> Enum.reverse()

    %ExM3U8.MediaPlaylist{timeline: timeline, info: info}
  end

  defp merge_media_playlists(video, nil), do: get_absolute_media_playlist(video)

  defp merge_media_playlists(video, playlist) do
    new_playlist = video |> get_absolute_media_playlist

    %ExM3U8.MediaPlaylist{
      playlist
      | timeline: playlist.timeline ++ [%ExM3U8.Tags.Discontinuity{} | new_playlist.timeline],
        info: %ExM3U8.MediaPlaylist.Info{
          playlist.info
          | target_duration: max(playlist.info.target_duration, new_playlist.info.target_duration)
        }
    }
  end

  defp merge_playlists(videos) do
    example_playlist = videos |> Enum.at(0) |> get_playlist()

    streams =
      Enum.map(videos, fn v ->
        [item | _] = get_playlist(v) |> then(&Map.get(&1, :items))

        count =
          get_media_playlist(v, @tracks.video)
          |> then(
            &Enum.count(&1.timeline, fn
              %ExM3U8.Tags.Segment{} -> true
              _ -> false
            end)
          )

        {item, count}
      end)

    {example_stream, _} = streams |> Enum.at(0)

    if Enum.all?(streams, fn {x, _} ->
         example_stream.resolution == x.resolution && example_stream.codecs == x.codecs
       end) do
      max_bandwidth =
        Enum.map(streams, fn {stream, _} -> Map.get(stream, :bandwidth) end)
        |> Enum.max(&Ratio.gte?/2)

      avg_bandwidth =
        streams
        |> Enum.reduce({0, 0}, fn {s, count}, {avg_sum, count_sum} ->
          {avg_sum + s.average_bandwidth * count, count_sum + count}
        end)
        |> then(fn {avg, count} -> avg / count end)
        |> Ratio.trunc()

      {:ok,
       %{
         example_playlist
         | items: [
             %{example_stream | average_bandwidth: avg_bandwidth, bandwidth: max_bandwidth}
           ]
       }}
    else
      {:error, "Codecs or resolutions don't match"}
    end
  end

  defp insert_merged_video(videos, playlist, media_playlist) do
    [video | _] = videos

    duration = videos |> Enum.reduce(0, fn v, d -> d + v.duration end)

    result =
      %{video | duration: duration, id: nil, filename: nil}
      |> change()
      |> Video.put_video_url(video.type, video.format)
      |> Repo.insert()

    upload_to = fn uuid, track_atom, content ->
      Storage.upload(
        content,
        "#{uuid}/#{@tracks[track_atom]}",
        content_type: "application/x-mpegURL"
      )
    end

    with {:ok, new_video} <- result,
         {:ok, _} <- upload_to.(new_video.uuid, :manifest, ExM3U8.serialize(playlist)),
         {:ok, _} <-
           upload_to.(
             new_video.uuid,
             :video,
             "#{ExM3U8.serialize(media_playlist)}#EXT-X-ENDLIST\n"
           ) do
      result
    end
  end

  def merge_streams(videos) do
    with {:ok, playlist} <- merge_playlists(videos),
         media_playlist <- Enum.reduce(videos, nil, &merge_media_playlists/2),
         {:ok, new_video} <- insert_merged_video(videos, playlist, media_playlist) do
      ids = Enum.map(videos, & &1.id)

      Repo.update_all(
        from(v in Video, where: v.id in ^ids),
        set: [
          visibility: :unlisted,
          deleted_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
        ]
      )

      {:ok, new_video}
    end
  end

  def get_playlist(video) do
    {:ok, resp} = get(video.url)
    {:ok, playlist} = ExM3U8.deserialize_playlist(resp.body, [])
    playlist
  end

  def get_media_playlist(video, uri) do
    url = "#{video.url_root}/#{uri}"

    with {:ok, resp} <- get(url),
         {:ok, playlist} <- ExM3U8.deserialize_media_playlist(resp.body, []) do
      playlist
    else
      _ -> nil
    end
  end

  def get_media_playlists(video) do
    %{
      video: get_media_playlist(video, @tracks.video),
      audio: get_media_playlist(video, @tracks.audio)
    }
  end

  def set_thumbnail!(id, path \\ nil) do
    video = Library.get_video!(id)
    {:ok, _} = Library.store_thumbnail_from_file(video, path || "/tmp/#{id}.png")
    {:ok, _} = Library.store_og_image_from_file(video, path || "/tmp/#{id}.png")
  end

  def set_title!(id, title) do
    video = Library.get_video!(id)
    user = Accounts.get_user!(video.user_id)
    {:ok, _} = Library.update_video(video, %{title: title})
    {:ok, _} = Accounts.update_settings(user, %{channel_tagline: title})
  end

  def nodes(), do: [Node.self() | Node.list()]

  def pipelines() do
    nodes() |> Enum.flat_map(&Membrane.Pipeline.list_pipelines/1)
  end

  def broadcasts() do
    pipelines() |> Enum.map(fn pid -> GenServer.call(pid, :get_video_id) end)
  end

  def multicast!(video_id) do
    pipelines()
    |> Enum.find(fn pid -> GenServer.call(pid, :get_video_id) == video_id end)
    |> send(:multicast_algora)
  end

  def download_chunks(video, chunks, dir) do
    Task.async_stream(
      Enum.with_index(chunks),
      fn {chunk, i} ->
        IO.puts("#{rounded(100 * i / length(chunks))}%")

        dl_path = "#{dir}/#{chunk}"

        if not File.exists?(dl_path) do
          {:ok, :saved_to_file} =
            :httpc.request(:get, {~c"#{video.url_root}/#{chunk}", []}, [],
              stream: ~c"#{dl_path}.part"
            )

          File.rename!("#{dl_path}.part", dl_path)
        end
      end,
      max_concurrency: 100,
      timeout: :infinity
    )
    |> Stream.map(fn {:ok, val} -> val end)
    |> Enum.to_list()
  end

  def download_video(video, dir) do
    playlists = get_media_playlists(video)

    video_chunks =
      for n <- playlists.video.timeline,
          Map.has_key?(n, :uri),
          do: n.uri

    audio_chunks =
      for n <- playlists.audio.timeline,
          Map.has_key?(n, :uri),
          do: n.uri

    {time, _} = :timer.tc(&download_chunks/3, [video, video_chunks ++ audio_chunks, dir])

    video_chunks
    |> Enum.map(fn chunk -> "#{dir}/#{chunk}" end)
    |> concatenate_files("#{dir}/video.mp4")

    audio_chunks
    |> Enum.map(fn chunk -> "#{dir}/#{chunk}" end)
    |> concatenate_files("#{dir}/audio.mp4")

    {_, 0} =
      System.cmd(
        "ffmpeg",
        [
          "-y",
          "-i",
          "#{dir}/video.mp4",
          "-i",
          "#{dir}/audio.mp4",
          "-c",
          "copy",
          "#{dir}/output.mp4"
        ]
      )

    %File.Stat{size: size} = File.stat!("#{dir}/output.mp4")

    IO.puts(
      "Downloaded #{rounded(size / 1_000_000)} MB in #{rounded(time / 1_000_000)} s (#{rounded(size / time)} MB/s)"
    )
  end

  def tmp_dir do
    case Algora.config([:mode]) do
      :prod ->
        "/data"

      _ ->
        System.tmp_dir!()
    end
  end

  def download(video) do
    dir = Path.join(tmp_dir(), video.uuid)

    File.mkdir_p!(dir)

    {time, _} = :timer.tc(&download_video/2, [video, dir])

    %File.Stat{size: size} = File.stat!("#{dir}/output.mp4")

    IO.puts("Transmuxed #{rounded(size / 1_000_000)} MB in #{rounded(time / 1_000_000)} s")
  end

  def save_download(video, cb \\ fn _ -> nil end) do
    mp4_basename = Slug.slugify("#{Date.to_string(video.inserted_at)}-#{video.title}")

    mp4_video =
      %Video{
        title: video.title,
        duration: video.duration,
        type: :vod,
        format: :mp4,
        is_live: false,
        visibility: :unlisted,
        user_id: video.user_id,
        transmuxed_from_id: video.id,
        thumbnail_url: video.thumbnail_url
      }
      |> change()
      |> Video.put_video_url(:vod, :mp4, mp4_basename)

    %{remote_path: mp4_remote_path} = mp4_video.changes

    mp4_local_path = Path.join([tmp_dir(), video.uuid, "output.mp4"])

    Storage.upload_from_filename(mp4_local_path, mp4_remote_path, cb, content_type: "video/mp4")

    Repo.insert!(mp4_video)
  end

  def concatenate_files(paths, output_file) do
    paths
    |> Stream.map(&stream_file/1)
    |> Stream.concat()
    |> Stream.into(File.stream!(output_file, [:write, :delayed]))
    |> Stream.run()
  end

  defp stream_file(file_path) do
    File.stream!(file_path, [], 2048)
  end

  def nearest_tigris_region() do
    %{scheme: scheme, host: host} = Application.fetch_env!(:ex_aws, :s3) |> Enum.into(%{})
    bucket_url = "#{scheme}#{host}/#{Algora.config([:buckets, :media])}"

    src_region = System.get_env("FLY_REGION") || "local"
    bytes = :crypto.strong_rand_bytes(1_000)

    {_time, {:ok, _}} = :timer.tc(&Storage.upload/3, [bytes, "0/#{src_region}.bin", []])

    {:ok, %{headers: headers}} = HTTPoison.get("#{bucket_url}/0/#{src_region}.bin")

    headers
    |> Enum.find(fn {k, _} -> k == "X-Tigris-Regions" end)
    |> then(fn {_, v} -> v end)
  end

  def speedtest(n \\ 1, size \\ 1_000_000) do
    bytes = :crypto.strong_rand_bytes(size)
    src_region = System.get_env("FLY_REGION") || "local"
    dst_region = nearest_tigris_region()

    for _ <- 1..n do
      {time, {:ok, _}} = :timer.tc(&Storage.upload/3, [bytes, "0/#{src_region}.bin", []])

      IO.puts(
        "Uploaded #{Float.round(size / 1.0e6, 1)} MB in #{Float.round(time / 1.0e6, 2)} s (#{Float.round(size / time, 2)} MB/s, #{src_region} -> #{dst_region})"
      )
    end

    :ok
  end

  def speedtest_par(n \\ 1, size \\ 1_000_000) do
    :rpc.multicall(nodes(), Algora.Admin, :speedtest, [n, size])
  end

  def speedtest_seq(n \\ 1, size \\ 1_000_000) do
    nodes() |> Enum.map(fn node -> :rpc.call(node, Algora.Admin, :speedtest, [n, size]) end)
  end

  defp rounded(num), do: Float.round(num, 1)
end
