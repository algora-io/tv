defmodule Algora.Library.VideoThumbnail do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  alias Algora.Library.Video

  schema "video_thumbnails" do
    field :minutes, :integer
    field :thumbnail_url, :string

    belongs_to :video, Video

    timestamps()
  end

  def put_video(%Ecto.Changeset{} = changeset, %Video{} = video) do
    put_assoc(changeset, :video, video)
  end
end
