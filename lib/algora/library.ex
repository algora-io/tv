defmodule Algora.Library do
  @moduledoc """
  The Library context.
  """

  require Logger
  import Ecto.Query, warn: false
  import Ecto.Changeset
  alias Algora.Accounts.User
  alias Algora.{Repo, Accounts, Storage, Cache, ML}
  alias Algora.Library.{Channel, Video, Events, Subtitle, Segment}

  @pubsub Algora.PubSub

  def subscribe_to_studio() do
    Phoenix.PubSub.subscribe(@pubsub, topic_studio())
  end

  def subscribe_to_livestreams() do
    Phoenix.PubSub.subscribe(@pubsub, topic_livestreams())
  end

  def subscribe_to_channel(%Channel{} = channel) do
    Phoenix.PubSub.subscribe(@pubsub, topic(channel.user_id))
  end

  def init_livestream!() do
    %Video{
      title: "",
      duration: 0,
      type: :livestream,
      format: :hls,
      is_live: true,
      visibility: :unlisted
    }
    |> change()
    |> Video.put_video_url(:hls)
    |> Repo.insert!()
  end

  def init_mp4!(%Phoenix.LiveView.UploadEntry{} = entry, tmp_path, %User{} = user) do
    title = Path.basename(entry.client_name, ".mp4")
    basename = Slug.slugify(title)

    video =
      %Video{
        title: title,
        duration: 0,
        type: :vod,
        format: :mp4,
        is_live: false,
        visibility: :unlisted,
        user_id: user.id,
        local_path: tmp_path,
        channel_handle: user.handle,
        channel_name: user.name
      }
      |> change()
      |> Video.put_video_meta(:mp4, basename)

    dir = Path.join("/data", video.changes.uuid)
    File.mkdir_p!(dir)
    local_path = Path.join(dir, video.changes.filename)
    File.cp!(tmp_path, local_path)

    video
    |> put_change(:local_path, local_path)
    |> Repo.insert!()
  end

  def transmux_to_mp4(%Video{} = video, cb) do
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
      |> Video.put_video_url(:mp4, mp4_basename)

    %{uuid: mp4_uuid, filename: mp4_filename, remote_path: mp4_remote_path} = mp4_video.changes

    dir = Path.join("/data", mp4_uuid)
    File.mkdir_p!(dir)
    mp4_local_path = Path.join(dir, mp4_filename)

    cb.(%{stage: :transmuxing, done: 1, total: 1})
    System.cmd("ffmpeg", ["-i", video.url, "-c", "copy", mp4_local_path])

    Storage.upload_from_filename(mp4_local_path, mp4_remote_path, cb)
    mp4_video = Repo.insert!(mp4_video)

    File.rm!(mp4_local_path)

    mp4_video
  end

  def transmux_to_hls(%Video{} = video, cb) do
    duration =
      case get_duration(video) do
        {:ok, duration} -> duration
        {:error, _} -> 0
      end

    hls_video =
      %Video{
        title: video.title,
        duration: duration,
        type: :vod,
        format: :hls,
        is_live: false,
        visibility: video.visibility,
        user_id: video.user_id
      }
      |> change()
      |> Video.put_video_url(:hls)

    %{uuid: hls_uuid, filename: hls_filename} = hls_video.changes

    dir = Path.join("/data", hls_uuid)
    File.mkdir_p!(dir)
    hls_local_path = Path.join(dir, hls_filename)

    cb.(%{stage: :transmuxing, done: 1, total: 1})

    System.cmd("ffmpeg", [
      "-i",
      video.local_path,
      "-c",
      "copy",
      "-start_number",
      "0",
      "-hls_time",
      "2",
      "-hls_list_size",
      "0",
      "-f",
      "hls",
      hls_local_path
    ])

    files = Path.wildcard("#{dir}/*")

    files
    |> Stream.map(fn hls_local_path ->
      cb.(%{stage: :persisting, done: 1, total: length(files)})
      hls_local_path
    end)
    |> Enum.each(fn hls_local_path ->
      Storage.upload_from_filename(
        hls_local_path,
        "#{hls_uuid}/#{Path.basename(hls_local_path)}"
      )
    end)

    hls_video = Repo.insert!(hls_video)

    cb.(%{stage: :generating_thumbnail, done: 1, total: 1})
    {:ok, hls_video} = store_thumbnail_from_file(hls_video, video.local_path)

    # TODO: should probably keep the file around for a while for any additional processing
    # requests from user?
    File.rm!(video.local_path)

    Repo.delete!(video)

    hls_video
    |> change()
    |> put_change(:id, video.id)
    |> Repo.update!()
  end

  def get_latest_video(%User{} = user) do
    from(v in Video,
      join: u in User,
      on: v.user_id == u.id,
      where: u.id == ^user.id,
      select_merge: %{
        channel_handle: u.handle,
        channel_name: u.name,
        channel_avatar_url: u.avatar_url
      },
      order_by: [desc: v.inserted_at],
      limit: 1
    )
    |> Repo.one()
  end

  def transcribe_video(%Video{} = video, cb) do
    dir = Path.join(System.tmp_dir!(), video.uuid)
    File.mkdir_p!(dir)
    mp3_local_path = Path.join(dir, "index.mp3")

    cb.(%{stage: :transmuxing, done: 1, total: 1})
    System.cmd("ffmpeg", ["-i", video.url, "-vn", mp3_local_path])

    Storage.upload_from_filename(mp3_local_path, "#{video.uuid}/index.mp3", cb)

    File.rm!(mp3_local_path)

    Cache.fetch("#{Video.slug(video)}/transcription", fn ->
      ML.transcribe_video_async("#{video.url_root}/index.mp3")
    end)
  end

  def get_mp4_video(id) do
    from(v in Video,
      where: v.format == :mp4 and (v.transmuxed_from_id == ^id or v.id == ^id),
      join: u in User,
      on: v.user_id == u.id,
      select_merge: %{
        channel_handle: u.handle,
        channel_name: u.name,
        channel_avatar_url: u.avatar_url
      }
    )
    |> Repo.one()
  end

  def toggle_streamer_live(%Video{} = video, is_live) do
    video = get_video!(video.id)
    user = Accounts.get_user!(video.user_id)

    if user.visibility == :public do
      Repo.update_all(from(u in Accounts.User, where: u.id == ^video.user_id),
        set: [is_live: is_live]
      )
    end

    Repo.update_all(
      from(v in Video,
        where: v.user_id == ^video.user_id and (v.id != ^video.id or not (^is_live))
      ),
      set: [is_live: false]
    )

    video = get_video!(video.id)

    video =
      with false <- is_live,
           {:ok, duration} <- get_duration(video),
           {:ok, video} <- video |> change() |> put_change(:duration, duration) |> Repo.update() do
        video
      else
        _ -> video
      end

    msg =
      case is_live do
        true -> %Events.LivestreamStarted{video: video}
        false -> %Events.LivestreamEnded{video: video}
      end

    Phoenix.PubSub.broadcast!(@pubsub, topic_livestreams(), {__MODULE__, msg})

    sink_url = Algora.config([:event_sink, :url])

    if sink_url && user.visibility == :public do
      identity =
        from(i in Algora.Accounts.Identity,
          join: u in assoc(i, :user),
          where: u.id == ^video.user_id and i.provider == "github",
          order_by: [asc: i.inserted_at]
        )
        |> Repo.one()
        |> Repo.preload(:user)

      body =
        Jason.encode_to_iodata!(%{
          event_kind: if(is_live, do: :livestream_started, else: :livestream_ended),
          stream_id: video.uuid,
          url: "#{AlgoraWeb.Endpoint.url()}/#{identity.user.handle}",
          github_user: %{
            id: String.to_integer(identity.provider_id),
            login: identity.provider_login
          }
        })

      Finch.build(:post, sink_url, [{"content-type", "application/json"}], body)
      |> Finch.request(Algora.Finch)
    end
  end

  def toggle_visibility!(%Video{} = video) do
    new_visibility =
      case video.visibility do
        :public -> :unlisted
        _ -> :public
      end

    video |> change() |> put_change(:visibility, new_visibility) |> Repo.update!()
  end

  defp get_playlist(%Video{} = video) do
    with {:ok, resp} <- Finch.build(:get, video.url) |> Finch.request(Algora.Finch) do
      ExM3U8.deserialize_playlist(resp.body, [])
    end
  end

  defp get_media_playlist(%Video{} = video, uri) do
    url = "#{video.url_root}/#{uri}"

    with {:ok, resp} <- Finch.build(:get, url) |> Finch.request(Algora.Finch) do
      ExM3U8.deserialize_media_playlist(resp.body, [])
    end
  end

  defp get_media_playlist(%Video{} = video) do
    with {:ok, playlist} <- get_playlist(video) do
      uri = playlist.items |> Enum.find(&match?(%{uri: _}, &1)) |> then(& &1.uri)
      get_media_playlist(video, uri)
    end
  end

  def get_duration(%Video{format: :hls} = video) do
    with {:ok, playlist} <- get_media_playlist(video) do
      duration =
        playlist.timeline
        |> Enum.filter(&match?(%{duration: _}, &1))
        |> Enum.reduce(0, fn x, acc -> acc + x.duration end)

      {:ok, round(duration)}
    end
  end

  def get_duration(%Video{local_path: nil}), do: {:error, :not_implemented}

  def get_duration(%Video{local_path: local_path}) do
    case FFprobe.duration(local_path) do
      :no_duration -> {:error, :no_duration}
      {:error, error} -> {:error, error}
      duration -> {:ok, round(duration)}
    end
  end

  def to_hhmmss(duration) when is_integer(duration) do
    hours = div(duration, 60 * 60)
    minutes = div(duration - hours * 60 * 60, 60)
    seconds = rem(duration - hours * 60 * 60 - minutes * 60, 60)

    if(hours == 0, do: [minutes, seconds], else: [hours, minutes, seconds])
    |> Enum.map_join(":", fn count -> String.pad_leading("#{count}", 2, ["0"]) end)
  end

  def to_hhmmss(duration) when is_float(duration) do
    to_hhmmss(trunc(duration))
  end

  def unsubscribe_to_channel(%Channel{} = channel) do
    Phoenix.PubSub.unsubscribe(@pubsub, topic(channel.user_id))
  end

  defp create_thumbnail_from_file(%Video{} = video, src_path, opts) do
    dst_path = Path.join(System.tmp_dir!(), "#{video.uuid}.jpeg")

    with :ok <- Thumbnex.create_thumbnail(src_path, dst_path, opts) do
      File.read(dst_path)
    end
  end

  defp create_thumbnail(%Video{} = video, contents, opts \\ []) do
    src_path = Path.join(System.tmp_dir!(), "#{video.uuid}.mp4")

    with :ok <- File.write(src_path, contents) do
      create_thumbnail_from_file(video, src_path, opts)
    end
  end

  def store_thumbnail_from_file(%Video{} = video, src_path, opts \\ []) do
    with {:ok, thumbnail} <- create_thumbnail_from_file(video, src_path, opts),
         {:ok, _} <-
           Storage.upload(thumbnail, "#{video.uuid}/index.jpeg", content_type: "image/jpeg") do
      video
      |> change()
      |> put_change(:thumbnail_url, "#{video.url_root}/index.jpeg")
      |> Repo.update()
    end
  end

  def store_thumbnail(%Video{} = video, contents) do
    with {:ok, thumbnail} <- create_thumbnail(video, contents),
         {:ok, _} <-
           Storage.upload(thumbnail, "#{video.uuid}/index.jpeg", content_type: "image/jpeg") do
      video
      |> change()
      |> put_change(:thumbnail_url, "#{video.url_root}/index.jpeg")
      |> Repo.update()
    end
  end

  defp create_og(src_path, dst_path, _opts) do
    base_image = Image.open!(src_path)

    {width, height, _} = Image.shape(base_image)

    overlay_svg = """
      <svg viewbox="0 0 #{width} #{height}" width="#{width}" height="#{height}"
        xmlns="http://www.w3.org/2000/svg">
        <defs>
            <filter x="0" y="0" width="1.06" height="1" id="solid">
                <feFlood flood-color="#ef4444" result="bg" />
                <feMerge>
                    <feMergeNode in="bg" />
                    <feMergeNode in="SourceGraphic" />
                </feMerge>
            </filter>

            <filter id="rounded-corners" x="-8%" width="122%" y="-37%" height="150%">
                <feFlood flood-color="#ef4444" />
                <feGaussianBlur stdDeviation="42" />
                <feComponentTransfer>
                    <feFuncA type="table" tableValues="0 0 0 1" />
                </feComponentTransfer>

                <feComponentTransfer>
                    <feFuncA type="table" tableValues="0 1 1 1 1 1 1 1" />
                </feComponentTransfer>
                <feComposite operator="over" in="SourceGraphic" />
            </filter>
        </defs>
        <g filter="url(#rounded-corners)">
            <svg xmlns="http://www.w3.org/2000/svg" width="180" height="180" viewBox="0 0 24 24"
                x="#{trunc(width / 2) - 180}" y="20"
                fill="none" stroke="#fff" stroke-width="2" stroke-linecap="round"
                stroke-linejoin="round"
                class="icon icon-tabler icons-tabler-outline icon-tabler-access-point">
                <path stroke="none" d="M0 0h24v24H0z" fill="none" />
                <path d="M12 12l0 .01" />
                <path d="M14.828 9.172a4 4 0 0 1 0 5.656" />
                <path d="M17.657 6.343a8 8 0 0 1 0 11.314" />
                <path d="M9.168 14.828a4 4 0 0 1 0 -5.656" />
                <path d="M6.337 17.657a8 8 0 0 1 0 -11.314" />
            </svg>
            <text font-style="normal" font-weight="bold" xml:space="preserve" font-family="'Bangers'"
                font-size="122" x="#{trunc(width / 2) + 150}" y="150" dominant-baseline="middle"
                text-anchor="middle"
                stroke-width="0" stroke="#000" fill="#fff">LIVE</text>
        </g>
    </svg>
    """

    {overlay, _} = Vix.Vips.Operation.svgload_buffer!(overlay_svg)

    og_image = Image.compose!(base_image, overlay)
    Image.write!(og_image, dst_path)

    :ok
  end

  defp create_og_image_from_file(%Video{} = video, src_path, opts) do
    dst_path = Path.join(System.tmp_dir!(), "#{video.uuid}-og.png")

    with :ok <- create_og(src_path, dst_path, opts) do
      File.read(dst_path)
    end
  end

  defp create_og_image(%Video{} = video, opts \\ []) do
    src_path = Path.join(System.tmp_dir!(), "#{video.uuid}.jpeg")
    create_og_image_from_file(video, src_path, opts)
  end

  def store_og_image_from_file(%Video{} = video, src_path, opts \\ []) do
    with {:ok, og_image} <- create_og_image_from_file(video, src_path, opts),
         {:ok, _} <-
           Storage.upload(og_image, "#{video.uuid}/og.png", content_type: "image/png") do
      video
      |> change()
      |> put_change(:og_image_url, "#{video.url_root}/og.png")
      |> Repo.update()
    end
  end

  def store_og_image(%Video{} = video) do
    with {:ok, og_image} <- create_og_image(video),
         {:ok, _} <-
           Storage.upload(og_image, "#{video.uuid}/og.png", content_type: "image/png") do
      video
      |> change()
      |> put_change(:og_image_url, "#{video.url_root}/og.png")
      |> Repo.update()
    end
  end

  def get_thumbnail_url(%Video{} = video) do
    video.thumbnail_url || "#{AlgoraWeb.Endpoint.url()}/images/og/default.png"
  end

  def get_thumbnail_url(%User{} = user) do
    case get_latest_video(user) do
      # TODO:
      nil ->
        "#{AlgoraWeb.Endpoint.url()}/images/og/default.png"

      video ->
        get_thumbnail_url(video)
    end
  end

  def get_og_image_url(%Video{} = video) do
    video.og_image_url || get_thumbnail_url(video)
  end

  def get_og_image_url(%User{} = user) do
    case get_latest_video(user) do
      nil ->
        get_thumbnail_url(user)

      video ->
        get_og_image_url(video)
    end
  end

  def reconcile_livestream(%Video{} = video, stream_key) do
    user = Accounts.get_user_by!(stream_key: stream_key)

    result =
      Repo.update_all(from(v in Video, where: v.id == ^video.id),
        set: [user_id: user.id, title: user.channel_tagline, visibility: user.visibility]
      )

    case result do
      {1, _} -> {:ok, video}
      _ -> {:error, :invalid}
    end
  end

  def list_videos(limit \\ 100) do
    from(v in Video,
      join: u in User,
      on: v.user_id == u.id,
      limit: ^limit,
      where:
        not is_nil(v.url) and
          is_nil(v.transmuxed_from_id) and
          v.visibility == :public and
          is_nil(v.vertical_thumbnail_url) and
          (v.is_live == true or v.duration >= 120 or v.type == :vod),
      select_merge: %{
        channel_handle: u.handle,
        channel_name: u.name,
        channel_avatar_url: u.avatar_url
      }
    )
    |> order_by_inserted(:desc)
    |> Repo.all()
  end

  def list_videos_by_ids(ids) do
    videos =
      from(v in Video,
        join: u in User,
        on: v.user_id == u.id,
        select_merge: %{
          channel_handle: u.handle,
          channel_name: u.name,
          channel_avatar_url: u.avatar_url
        },
        where: v.id in ^ids
      )
      |> Repo.all()

    video_by_id = fn id ->
      videos
      |> Enum.find(fn s -> s.id == id end)
    end

    ids
    |> Enum.reduce([], fn id, acc -> [video_by_id.(id) | acc] end)
    |> Enum.filter(& &1)
    |> Enum.reverse()
  end

  def list_shorts(limit \\ 100) do
    from(v in Video,
      join: u in User,
      on: v.user_id == u.id,
      limit: ^limit,
      where:
        not is_nil(v.url) and
          is_nil(v.transmuxed_from_id) and v.visibility == :public and
          not is_nil(v.vertical_thumbnail_url),
      select_merge: %{
        channel_handle: u.handle,
        channel_name: u.name,
        channel_avatar_url: u.avatar_url
      }
    )
    |> order_by_inserted(:desc)
    |> Repo.all()
  end

  def list_channel_videos(%Channel{} = channel, limit \\ 100) do
    from(v in Video,
      limit: ^limit,
      join: u in User,
      on: v.user_id == u.id,
      select_merge: %{
        channel_handle: u.handle,
        channel_name: u.name,
        channel_avatar_url: u.avatar_url
      },
      where:
        not is_nil(v.url) and
          is_nil(v.transmuxed_from_id) and
          v.user_id == ^channel.user_id
    )
    |> order_by_inserted(:desc)
    |> Repo.all()
  end

  def list_studio_videos(%Channel{} = channel, limit \\ 100) do
    from(v in Video,
      limit: ^limit,
      join: u in assoc(v, :user),
      left_join: m in assoc(v, :messages),
      group_by: [v.id, u.handle, u.name, u.avatar_url],
      select_merge: %{
        channel_handle: u.handle,
        channel_name: u.name,
        channel_avatar_url: u.avatar_url,
        messages_count: count(m.id)
      },
      where:
        is_nil(v.transmuxed_from_id) and
          v.user_id == ^channel.user_id
    )
    |> order_by_inserted(:desc)
    |> Repo.all()
  end

  def list_active_channels(opts) do
    from(u in Algora.Accounts.User,
      where: u.is_live,
      limit: ^Keyword.fetch!(opts, :limit),
      order_by: [desc: u.updated_at],
      select: struct(u, [:id, :handle, :channel_tagline, :avatar_url, :external_homepage_url])
    )
    |> Repo.all()
    |> Enum.map(&get_channel!/1)
  end

  def get_channel!(%Accounts.User{} = user) do
    %Channel{
      user_id: user.id,
      handle: user.handle,
      name: user.name || user.handle,
      tagline: user.channel_tagline,
      avatar_url: user.avatar_url,
      external_homepage_url: user.external_homepage_url,
      is_live: user.is_live,
      bounties_count: user.bounties_count,
      orgs_contributed: user.orgs_contributed,
      tech: user.tech
    }
  end

  def owns_channel?(%Accounts.User{} = user, %Channel{} = channel) do
    user.id == channel.user_id
  end

  def player_type(%Video{format: :mp4}), do: "video/mp4"
  def player_type(%Video{format: :hls}), do: "application/x-mpegURL"
  def player_type(%Video{format: :youtube}), do: "video/youtube"

  def get_video!(id),
    do:
      from(v in Video,
        where: v.id == ^id,
        join: u in User,
        on: v.user_id == u.id,
        select_merge: %{
          channel_handle: u.handle,
          channel_name: u.name,
          channel_avatar_url: u.avatar_url
        }
      )
      |> Repo.one!()

  def update_video(%Video{} = video, attrs) do
    video
    |> Video.changeset(attrs)
    |> Repo.update()
  end

  def delete_video(%Video{} = video) do
    Repo.delete(video)
  end

  defp order_by_inserted(%Ecto.Query{} = query, direction) when direction in [:asc, :desc] do
    from(s in query, order_by: [{^direction, s.inserted_at}])
  end

  defp topic(user_id) when is_integer(user_id), do: "channel:#{user_id}"

  def topic_livestreams(), do: "livestreams"

  def topic_studio(), do: "studio"

  def list_segments(%Video{} = video) do
    from(s in Segment, where: s.video_id == ^video.id, order_by: [asc: s.start])
    |> Repo.all()
  end

  def list_segments_by_ids(ids) do
    segments = from(s in Segment, where: s.id in ^ids) |> Repo.all()

    segment_by_id = fn id -> segments |> Enum.find(fn s -> s.id == id end) end

    ids
    |> Enum.reduce([], fn id, acc -> [segment_by_id.(id) | acc] end)
    |> Enum.filter(& &1)
    |> Enum.reverse()
  end

  def list_subtitles(%Video{} = video) do
    from(s in Subtitle, where: s.video_id == ^video.id, order_by: [asc: s.start])
    |> Repo.all()
  end

  def get_subtitle!(id), do: Repo.get!(Subtitle, id)

  def create_subtitle(%Video{} = video, attrs \\ %{}) do
    %Subtitle{video_id: video.id}
    |> Subtitle.changeset(attrs)
    |> Repo.insert()
  end

  def update_subtitle(%Subtitle{} = subtitle, attrs) do
    subtitle
    |> Subtitle.changeset(attrs)
    |> Repo.update()
  end

  def delete_subtitle(%Subtitle{} = subtitle) do
    Repo.delete(subtitle)
  end

  def change_subtitle(%Subtitle{} = subtitle, attrs \\ %{}) do
    Subtitle.changeset(subtitle, attrs)
  end

  def save_subtitle(sub) do
    %Subtitle{id: sub["id"]}
    |> Subtitle.changeset(%{start: sub["start"], end: sub["end"], body: sub["body"]})
    |> Repo.update!()
  end

  def save_subtitles(data) do
    Jason.decode!(data)
    |> Enum.take(100)
    |> Enum.map(&save_subtitle/1)
    |> length
  end

  defp broadcast!(topic, msg) do
    Phoenix.PubSub.broadcast!(@pubsub, topic, {__MODULE__, msg})
  end

  def broadcast_processing_progressed!(stage, video, pct) do
    broadcast!(topic_studio(), %Events.ProcessingProgressed{video: video, stage: stage, pct: pct})
  end

  def broadcast_processing_completed!(action, video, url) do
    broadcast!(topic_studio(), %Events.ProcessingCompleted{action: action, video: video, url: url})
  end

  def broadcast_processing_failed!(video, attempt, max_attempts) do
    broadcast!(topic_studio(), %Events.ProcessingFailed{
      video: video,
      attempt: attempt,
      max_attempts: max_attempts
    })
  end
end
