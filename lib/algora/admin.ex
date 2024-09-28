import Ecto.Query, warn: false
import Ecto.Changeset
alias Algora.{Accounts, Library, Storage, Repo}
alias Algora.Library.Video

defmodule Algora.Admin do

  def kill_ad_overlay_processes do
    find_ad_overlay_processes() |> Enum.each(&Process.exit(&1, :kill))
  end

  def find_ad_overlay_processes do
    nodes()
    |> Enum.flat_map(fn node ->
      :rpc.call(node, __MODULE__, :find_local_ad_overlay_processes, [])
    end)
  end

  def kill_local_ad_overlay_processes do
    find_local_ad_overlay_processes() |> Enum.each(&Process.exit(&1, :kill))
  end

  def find_liveview_processes(module, function \\ :mount, arity \\ 3) do
    nodes()
    |> Enum.flat_map(fn node ->
      :rpc.call(node, __MODULE__, :find_local_liveview_processes, [module, function, arity])
    end)
  end

  def find_local_liveview_processes(module, function \\ :mount, arity \\ 3) do
    :erlang.processes()
    |> Enum.filter(&local_process_matches?(&1, [{module, function, arity}]))
  end

  def find_local_ad_overlay_processes do
    find_local_liveview_processes(AlgoraWeb.AdOverlayLive)
  end

  defp local_process_matches?(pid, match_patterns) do
    case Process.info(pid, [:dictionary]) do
      [dictionary: dict] ->
        dict
        |> Keyword.get(:"$initial_call")
        |> then(&Enum.any?(match_patterns, fn pattern -> pattern == &1 end))

      _ ->
        false
    end
  end

  def whoami(), do: {System.get_env("FLY_REGION"), Node.self()}

  defp get(url) do
    Finch.build(:get, url) |> Finch.request(Algora.Finch)
  end

  defp get_absolute_media_playlist(video, manifest_name) do
    %ExM3U8.MediaPlaylist{timeline: timeline, info: info} =
      get_media_playlist(video, manifest_name)

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

  defp merge_media_playlists(videos, playlist) do
    manifest_names = Enum.map(playlist.items, &Map.get(&1, :uri))
    merge_media_playlists(videos, videos, nil, manifest_names, [{"index.m3u8", playlist}])
  end

  defp merge_media_playlists(_all, _videos, _playlist, [], acc), do: acc
  defp merge_media_playlists(all, [], playlist, [manifest_name | manifest_names], acc) do
    merge_media_playlists(all, all, nil, manifest_names, [{manifest_name, playlist}|acc])
  end
  defp merge_media_playlists(all, [video|videos], nil, [manifest_name|_] = manifest_names, acc) do
    new_playlist = video |> get_absolute_media_playlist(manifest_name)
    merge_media_playlists(all, videos, new_playlist, manifest_names, acc)
  end
  defp merge_media_playlists(all, [video|videos], playlist, [manifest_name|_] = manifest_names, acc) do
    new_playlist = video |> get_absolute_media_playlist(manifest_name)
    merge_media_playlists(all, videos, %ExM3U8.MediaPlaylist{
      playlist
      | timeline: playlist.timeline ++ [%ExM3U8.Tags.Discontinuity{} | new_playlist.timeline],
        info: %ExM3U8.MediaPlaylist.Info{
          playlist.info
          | target_duration: max(playlist.info.target_duration, new_playlist.info.target_duration)
        }
    }, manifest_names, acc)
  end

  defp merge_playlists(videos) do
    example_playlist = videos |> Enum.at(0) |> get_playlist()
    manifest_names = Enum.map(example_playlist.items, &Map.get(&1, :uri))
    playlists = Enum.reduce(manifest_names, %{items: []}, fn(manifest_name, acc) ->
      streams = Enum.map(videos, fn v ->
        item = get_playlist(v)
        |> Map.get(:items)
        |> Enum.find(&match?(^manifest_name, &1.uri))
        count = get_media_playlist(v, manifest_name)
        |> then(&Enum.count(&1.timeline, fn
            %ExM3U8.Tags.Segment{} -> true
            _ -> false
          end))
        {item, count}
      end)

      {example_stream, _} = streams |> Enum.find(&match?(manifest_name, elem(&1, 0).uri))

      if Enum.all?(streams, fn {x, _} -> example_stream.resolution == x.resolution && example_stream.codecs == x.codecs end) do
        max_bandwidth = Enum.map(streams, fn {stream, _} -> Map.get(stream, :bandwidth) end) |> Enum.max(&Ratio.gte?/2)
        avg_bandwidth = streams
          |> Enum.reduce({0, 0}, fn {s, count}, {avg_sum, count_sum} -> {avg_sum + s.average_bandwidth * count, count_sum + count} end)
          |> then(fn {avg, count} -> avg / count end )
          |> Ratio.trunc()

        %{example_playlist | items: [
          %{ example_stream | average_bandwidth: avg_bandwidth,  bandwidth: max_bandwidth }
          | acc.items
        ]}
      else
        IO.puts("Codecs or resolutions don't match in manifest #{manifest_name}. Skipping.")
        acc
      end
    end)

    {:ok, playlists}
  end

  defp insert_merged_video(videos) do
    [video | _] = videos

    duration = videos |> Enum.reduce(0, fn v, d -> d + v.duration end)
    %{video | duration: duration, id: nil, filename: nil}
      |> change()
      |> Video.put_video_url(:vod, video.format)
      |> Repo.insert()
  end

  def upload_merged_streams(video, playlists) do
    upload_to = fn uuid, manifest_name, content -> Storage.upload(
      content,
      "#{uuid}/#{manifest_name}",
      content_type: "application/x-mpegURL"
    ) end

    Enum.all? playlists, fn
      ({"index.m3u8" = manifest_name, playlist}) ->
        manifest = ExM3U8.serialize(playlist)
        match?({:ok, _}, upload_to.(video.uuid, manifest_name, manifest))
      ({manifest_name, playlist}) ->
        manifest = "#{ExM3U8.serialize(playlist)}#EXT-X-ENDLIST\n"
        match?({:ok, _}, upload_to.(video.uuid, manifest_name, manifest))
    end
  end

  def merge_streams(videos) do
    with {:ok, playlist} <- merge_playlists(videos),
      media_playlists <- merge_media_playlists(videos, playlist),
      {:ok, new_video} <- insert_merged_video(videos),
      true <- upload_merged_streams(new_video, media_playlists) do
        ids = Enum.map(videos, &(&1.id))
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
    with {:ok, resp} <- get(get_playlist_url(video, uri)),
         {:ok, playlist} <- ExM3U8.deserialize_media_playlist(resp.body, []) do
      playlist
    else
      _ -> nil
    end
  end

  def get_playlist_url(video, %ExM3U8.Tags.Stream{ uri: uri }), do:
    get_playlist_url(video, uri)
  def get_playlist_url(video, uri) do
    String.replace_suffix(video.url, "index.m3u8", uri )
  end

  def get_media_playlists(video) do
    with {:ok, master_resp} <- get(video.url),
         {:ok, master_playlist} <- ExM3U8.deserialize_multivariant_playlist(master_resp.body, []) do
      Enum.reduce(master_playlist.items, %{}, fn(tag, acc) ->
        Map.put(acc, tag.uri, get_media_playlist(video, tag))
      end)
    end
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

  def nodes(), do: Node.list([:this, :visible])

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
        name = URI.parse(chunk).path |> String.split("/") |> List.last()
        dl_path = "#{dir}/#{i}-#{name}"
        if not File.exists?(dl_path) do
          {:ok, :saved_to_file} =
            :httpc.request(:get, {chunk, []}, [],
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
    timeline = playlists |> Map.values() |> List.first() |> Map.get(:timeline)
    video_chunks =
      for n <- timeline,
          Map.has_key?(n, :uri),
      do: n.uri

    {time, _} = :timer.tc(&download_chunks/3, [video, video_chunks, dir])

    video_chunks
    |> Enum.with_index() |> Enum.map(fn {chunk, i} ->
        name = URI.parse(chunk).path |> String.split("/") |> List.last()
      "#{dir}/#{i}-#{name}"
    end)
    |> concatenate_files("#{dir}/video.mp4")

    {_, 0} =
      System.cmd(
        "ffmpeg",
        [
          "-y",
          "-i",
          "#{dir}/video.mp4",
          "-c",
          "copy",
          "#{dir}/output.mp4"
        ]
      )

    %File.Stat{size: size} = File.stat!("#{dir}/output.mp4")

    IO.puts(
      "Downloaded #{dir}/output.mp4 (#{rounded(size / 1_000_000)} MB) in #{rounded(time / 1_000_000)} s (#{rounded(size / time)} MB/s)"
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
