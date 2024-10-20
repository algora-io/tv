defmodule Algora.Library.Video do
  require Logger
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  alias Algora.Accounts.User
  alias Algora.Library.Video
  alias Algora.Storage
  alias Algora.Shows.Show
  alias Algora.Chat.Message
  alias Algora.Ads.{Appearance, ContentMetrics, ProductReview}

  @type uuid :: String.t()
  @type type :: :vod | :livestream
  @type format :: :mp4 | :hls | :youtube

  @type t() :: %__MODULE__{}

  schema "videos" do
    field :duration, :integer
    field :title, :string
    field :description, :string
    field :type, Ecto.Enum, values: [vod: 1, livestream: 2]
    field :format, Ecto.Enum, values: [mp4: 1, hls: 2, youtube: 3]
    field :corrupted, :boolean, default: false
    field :is_live, :boolean, default: false
    field :thumbnail_url, :string
    field :vertical_thumbnail_url, :string
    field :og_image_url, :string
    field :url, :string
    field :url_root, :string
    field :uuid, :string
    field :filename, :string
    field :channel_handle, :string, virtual: true
    field :channel_name, :string, virtual: true
    field :channel_avatar_url, :string, virtual: true
    field :messages_count, :integer, virtual: true, default: 0
    field :visibility, Ecto.Enum, values: [public: 1, unlisted: 2]
    field :remote_path, :string
    field :local_path, :string
    field :deleted_at, :naive_datetime

    belongs_to :user, User
    belongs_to :show, Show
    belongs_to :transmuxed_from, Video

    has_one :content_metrics, ContentMetrics
    has_many :messages, Message
    has_many :appearances, Appearance
    has_many :product_reviews, ProductReview

    timestamps()
  end

  @doc false
  def changeset(video, attrs) do
    video
    |> cast(attrs, [:title])
    |> validate_required([:title])
  end

  def change_thumbnail(video, thumbnail_url \\ "") do
    video
    |> change()
    |> put_change(:thumbnail_url, thumbnail_url)
  end

  def put_user(%Ecto.Changeset{} = changeset, %User{} = user) do
    put_assoc(changeset, :user, user)
  end

  @spec put_video_uuid(Ecto.Changeset.t(), type()) :: Ecto.Changeset.t()
  def put_video_uuid(%Ecto.Changeset{} = changeset, type) do
    if changeset.valid? do
      uuid = Ecto.UUID.generate()

      changeset
      |> put_change(:uuid, uuid)
      |> put_change(:url_root, url_root(type, uuid))
    else
      changeset
    end
  end

  @spec put_video_meta(Ecto.Changeset.t(), type(), format(), String.t()) :: Ecto.Changeset.t()
  def put_video_meta(%Ecto.Changeset{} = changeset, type, format, basename \\ "index") do
    if changeset.valid? do
      filename = "#{basename}#{fileext(format)}"

      changeset
      |> put_video_uuid(type)
      |> put_change(:filename, filename)
    else
      changeset
    end
  end

  @spec put_video_url(Ecto.Changeset.t(), type(), format(), String.t()) :: Ecto.Changeset.t()
  def put_video_url(%Ecto.Changeset{} = changeset, type, format, basename \\ "index") do
    if changeset.valid? do
      changeset = changeset |> put_video_meta(type, format, basename)
      %{uuid: uuid, filename: filename} = changeset.changes

      changeset
      |> put_change(:url, url(type, uuid, filename))
      |> put_change(:remote_path, "#{uuid}/#{filename}")
    else
      changeset
    end
  end

  @spec fileext(format()) :: String.t()
  defp fileext(:mp4), do: ".mp4"
  defp fileext(:hls), do: ".m3u8"

  @spec url_root(type(), uuid()) :: String.t()
  def url_root(:livestream, uuid), do: "#{AlgoraWeb.Endpoint.url()}/hls/#{uuid}"

  def url_root(:vod, uuid),
    do: "#{Storage.endpoint_url()}/#{Algora.config([:buckets, :media])}/#{uuid}"

  @spec url(type(), uuid(), String.t()) :: String.t()
  def url(type, uuid, filename), do: "#{url_root(type, uuid)}/#{filename}"

  @spec thumbnail_url(Video.t(), String.t()) :: String.t()
  def thumbnail_url(video, filename \\ "index.jpeg"),
    do: "#{Storage.endpoint_url()}/#{Algora.config([:buckets, :media])}/#{video.uuid}/#{filename}"

  @spec og_image_url(Video.t(), String.t()) :: String.t()
  def og_image_url(video, filename \\ "og.png"),
    do: "#{Storage.endpoint_url()}/#{Algora.config([:buckets, :media])}/#{video.uuid}/#{filename}"

  def slug(%Video{} = video), do: Slug.slugify("#{video.id}-#{video.title}")

  def id_from_slug(slug), do: slug |> String.split("-") |> Enum.at(0)

  def not_deleted(query) do
    from v in query, where: is_nil(v.deleted_at)
  end
end
