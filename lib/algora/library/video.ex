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
    field :is_live, :boolean, default: false
    field :thumbnail_url, :string
    field :vertical_thumbnail_url, :string
    field :url, :string
    field :url_root, :string
    field :uuid, :string
    field :channel_name, :string, virtual: true
    field :visibility, Ecto.Enum, values: [public: 1, unlisted: 2]
    belongs_to :user, Accounts.User

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

  def put_video_path(%Ecto.Changeset{} = changeset, type)
      when type in [:vod, :livestream] do
    if changeset.valid? do
      uuid = Ecto.UUID.generate()
      filename = "index#{fileext(type)}"

      changeset
      |> put_change(:uuid, uuid)
      |> put_change(:url, url(uuid, filename))
      |> put_change(:url_root, url_root(uuid))
    else
      changeset
    end
  end

  defp fileext(:vod), do: ".mp4"
  defp fileext(:livestream), do: ".m3u8"

  defp url_root(uuid) do
    bucket = Algora.config([:files, :bucket])
    %{scheme: scheme, host: host} = Application.fetch_env!(:ex_aws, :s3) |> Enum.into(%{})
    "#{scheme}#{host}/#{bucket}/#{uuid}"
  end

  defp url(uuid, filename), do: "#{url_root(uuid)}/#{filename}"
end
