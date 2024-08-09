defmodule Algora.Ads.Appearance do
  use Ecto.Schema
  import Ecto.Changeset
  alias Algora.Library.Video
  alias Algora.Ads.Ad

  schema "ad_appearances" do
    field :airtime, :integer

    belongs_to :ad, Ad
    belongs_to :video, Video

    timestamps()
  end

  def changeset(appearance, attrs) do
    appearance
    |> cast(attrs, [:airtime, :ad_id, :video_id])
    |> validate_required([:airtime, :ad_id, :video_id])
    |> foreign_key_constraint(:ad_id)
    |> foreign_key_constraint(:video_id)
  end
end
