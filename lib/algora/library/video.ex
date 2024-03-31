defmodule Algora.Library.Video do
  require Logger
  use Ecto.Schema
  import Ecto.Changeset

  alias Algora.Accounts

  @type t() :: %__MODULE__{}

  schema "videos" do
    field :duration, :integer
    field :title, :string
    field :type, Ecto.Enum, values: [vod: 1, livestream: 2]
    field :format, Ecto.Enum, values: [mp4: 1, hls: 2, youtube: 3]
    field :is_live, :boolean, default: false
    field :thumbnail_url, :string
    field :vertical_thumbnail_url, :string
    field :url, :string
    field :url_root, :string
    field :uuid, :string
    field :filename, :string
    field :channel_handle, :string, virtual: true
    field :channel_name, :string, virtual: true
    field :visibility, Ecto.Enum, values: [public: 1, unlisted: 2]
    field :remote_path, :string
    field :local_path, :string
    belongs_to :user, Accounts.User
    belongs_to :transmuxed_from, Algora.Library.Video

    timestamps()
  end

  @doc false
  def changeset(video, attrs) do
    video
    |> cast(attrs, [:title])
    |> validate_required([:title])
  end

  def put_user(%Ecto.Changeset{} = changeset, %Accounts.User{} = user) do
    put_assoc(changeset, :user, user)
  end

  def put_video_meta(%Ecto.Changeset{} = changeset, format, basename \\ "index")
      when format in [:mp4, :hls] do
    if changeset.valid? do
      uuid = Ecto.UUID.generate()
      filename = "#{basename}#{fileext(format)}"

      changeset
      |> put_change(:filename, filename)
      |> put_change(:uuid, uuid)
    else
      changeset
    end
  end

  def put_video_url(%Ecto.Changeset{} = changeset, format, basename \\ "index")
      when format in [:mp4, :hls] do
    if changeset.valid? do
      %{uuid: uuid, filename: filename} = changeset.changes

      changeset
      |> put_video_meta(format, basename)
      |> put_change(:url, url(uuid, filename))
      |> put_change(:url_root, url_root(uuid))
      |> put_change(:remote_path, "#{uuid}/#{filename}")
    else
      changeset
    end
  end

  defp fileext(:mp4), do: ".mp4"
  defp fileext(:hls), do: ".m3u8"

  defp url_root(uuid) do
    bucket = Algora.config([:files, :bucket])
    %{scheme: scheme, host: host} = Application.fetch_env!(:ex_aws, :s3) |> Enum.into(%{})
    "#{scheme}#{host}/#{bucket}/#{uuid}"
  end

  defp url(uuid, filename), do: "#{url_root(uuid)}/#{filename}"
end
