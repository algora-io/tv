defmodule Algora.Library.Video do
  require Logger
  use Ecto.Schema
  import Ecto.Changeset

  alias Algora.Accounts.User
  alias Algora.Library.Video
  alias Algora.Shows.Show
  alias Algora.Chat.Message

  @type t() :: %__MODULE__{}

  schema "videos" do
    field :duration, :integer
    field :title, :string
    field :description, :string
    field :type, Ecto.Enum, values: [vod: 1, livestream: 2]
    field :format, Ecto.Enum, values: [mp4: 1, hls: 2, youtube: 3]
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

    belongs_to :user, User
    belongs_to :show, Show
    belongs_to :transmuxed_from, Video

    has_many :messages, Message

    timestamps()
  end

  @doc false
  def changeset(video, attrs) do
    video
    |> cast(attrs, [:title])
    |> validate_required([:title])
  end

  def put_user(%Ecto.Changeset{} = changeset, %User{} = user) do
    put_assoc(changeset, :user, user)
  end

  def put_video_uuid(%Ecto.Changeset{} = changeset) do
    if changeset.valid? do
      uuid = Ecto.UUID.generate()

      changeset
      |> put_change(:uuid, uuid)
      |> put_change(:url_root, url_root(uuid))
    else
      changeset
    end
  end

  def put_video_meta(%Ecto.Changeset{} = changeset, format, basename \\ "index")
      when format in [:mp4, :hls] do
    if changeset.valid? do
      filename = "#{basename}#{fileext(format)}"

      changeset
      |> put_video_uuid()
      |> put_change(:filename, filename)
    else
      changeset
    end
  end

  def put_video_url(%Ecto.Changeset{} = changeset, format, basename \\ "index")
      when format in [:mp4, :hls] do
    if changeset.valid? do
      changeset = changeset |> put_video_meta(format, basename)
      %{uuid: uuid, filename: filename} = changeset.changes

      changeset
      |> put_change(:url, url(uuid, filename))
      |> put_change(:remote_path, "#{uuid}/#{filename}")
    else
      changeset
    end
  end

  defp fileext(:mp4), do: ".mp4"
  defp fileext(:hls), do: ".m3u8"

  defp url_root(uuid) do
    bucket = Algora.config([:buckets, :media])
    "#{AlgoraWeb.Endpoint.url()}/hls/#{bucket}/#{uuid}"
  end

  defp url(uuid, filename), do: "#{url_root(uuid)}/#{filename}"

  def slug(%Video{} = video), do: Slug.slugify("#{video.id}-#{video.title}")

  def id_from_slug(slug), do: slug |> String.split("-") |> Enum.at(0)
end
