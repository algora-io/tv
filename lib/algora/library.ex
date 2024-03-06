defmodule Algora.Library do
  @moduledoc """
  The Library context.
  """

  require Logger
  import Ecto.Query, warn: false
  import Ecto.Changeset
  alias Algora.Accounts.User
  alias Algora.{Repo, Accounts, Storage}
  alias Algora.Library.{Channel, Video, Events, Subtitle}

  @pubsub Algora.PubSub

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
      is_live: true,
      visibility: :unlisted
    }
    |> change()
    |> Video.put_video_path(:livestream)
    |> Repo.insert!()
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

      {:ok, _} =
        Finch.build(:post, sink_url, [{"content-type", "application/json"}], body)
        |> Finch.request(Algora.Finch)
    end
  end

  defp get_playlist(%Video{} = video) do
    url = "#{video.url_root}/index.m3u8"

    with {:ok, resp} <- Finch.build(:get, url) |> Finch.request(Algora.Finch) do
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

  def get_duration(%Video{type: :livestream} = video) do
    with {:ok, playlist} <- get_media_playlist(video) do
      duration =
        playlist.timeline
        |> Enum.filter(&match?(%{duration: _}, &1))
        |> Enum.reduce(0, fn x, acc -> acc + x.duration end)

      {:ok, round(duration)}
    end
  end

  def get_duration(%Video{type: :vod}) do
    {:error, :not_implemented}
  end

  def to_hhmmss(duration) when is_integer(duration) do
    hours = div(duration, 60 * 60)
    minutes = div(duration - hours * 60 * 60, 60)
    seconds = rem(duration - hours * 60 * 60 - minutes * 60, 60)

    if(hours == 0, do: [minutes, seconds], else: [hours, minutes, seconds])
    |> Enum.map_join(":", fn count -> String.pad_leading("#{count}", 2, ["0"]) end)
  end

  def unsubscribe_to_channel(%Channel{} = channel) do
    Phoenix.PubSub.unsubscribe(@pubsub, topic(channel.user_id))
  end

  defp create_thumbnail(%Video{} = video, contents) do
    input_path = Path.join(System.tmp_dir(), "#{video.uuid}.mp4")
    output_path = Path.join(System.tmp_dir(), "#{video.uuid}.jpeg")

    with :ok <- File.write(input_path, contents),
         :ok <- Thumbnex.create_thumbnail(input_path, output_path) do
      File.read(output_path)
    end
  end

  def store_thumbnail(%Video{} = video, contents) do
    with {:ok, thumbnail} <- create_thumbnail(video, contents),
         {:ok, _} <- Storage.upload_file("#{video.uuid}/index.jpeg", thumbnail) do
      :ok
    end
  end

  def reconcile_livestream(%Video{} = video, stream_key) do
    user =
      Accounts.get_user_by!(stream_key: stream_key)

    result =
      Repo.update_all(from(v in Video, where: v.id == ^video.id),
        set: [user_id: user.id, title: user.channel_tagline, visibility: user.visibility]
      )

    case result do
      {1, _} ->
        {:ok, video}

      _ ->
        {:error, :invalid}
    end
  end

  def list_videos(limit \\ 100) do
    from(v in Video,
      join: u in User,
      on: v.user_id == u.id,
      limit: ^limit,
      # TODO: remove vod check once current vod durations are backfilled
      where:
        v.visibility == :public and
          (v.is_live == true or v.duration >= 120 or v.type == :vod),
      select_merge: %{channel_name: u.name}
    )
    |> order_by_inserted(:desc)
    |> Repo.replica().all()
  end

  def list_channel_videos(%Channel{} = channel, limit \\ 100) do
    from(v in Video,
      limit: ^limit,
      join: u in User,
      on: v.user_id == u.id,
      select_merge: %{channel_name: u.name},
      where: v.user_id == ^channel.user_id
    )
    |> order_by_inserted(:desc)
    |> Repo.replica().all()
  end

  def list_active_channels(opts) do
    from(u in Algora.Accounts.User,
      where: u.is_live,
      limit: ^Keyword.fetch!(opts, :limit),
      order_by: [desc: u.updated_at],
      select: struct(u, [:id, :handle, :channel_tagline, :avatar_url, :external_homepage_url])
    )
    |> Repo.replica().all()
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

  defp youtube_id(%Video{url: url}) do
    url = URI.parse(url)
    root = ".#{url.host}"

    cond do
      root |> String.ends_with?(".youtube.com") ->
        %{"v" => id} = URI.decode_query(url.query)
        id

      root |> String.ends_with?(".youtu.be") ->
        "/" <> id = url.path
        id

      true ->
        :not_found
    end
  end

  def player_type(%Video{type: :livestream}), do: "application/x-mpegURL"

  def player_type(%Video{} = video) do
    case youtube_id(video) do
      :not_found -> "video/mp4"
      _ -> "video/youtube"
    end
  end

  def get_video!(id), do: Repo.replica().get!(Video, id)

  def update_video(%Video{} = video, attrs) do
    video
    |> Video.changeset(attrs)
    |> Repo.update()
  end

  defp order_by_inserted(%Ecto.Query{} = query, direction) when direction in [:asc, :desc] do
    from(s in query, order_by: [{^direction, s.inserted_at}])
  end

  defp topic(user_id) when is_integer(user_id), do: "channel:#{user_id}"

  def topic_livestreams(), do: "livestreams"

  def list_subtitles(%Video{} = video) do
    from(s in Subtitle, where: s.video_id == ^video.id, order_by: [asc: s.start])
    |> Repo.replica().all()
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
end
