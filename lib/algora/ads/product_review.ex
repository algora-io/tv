defmodule Algora.Ads.ProductReview do
  use Ecto.Schema
  import Ecto.Changeset
  alias Algora.Library.Video
  alias Algora.Ads.Ad

  schema "product_reviews" do
    field :clip_from, :integer
    field :clip_to, :integer
    field :thumbnail_url, :string

    belongs_to :ad, Ad
    belongs_to :video, Video

    timestamps()
  end

  def changeset(product_review, attrs) do
    product_review
    |> cast(attrs, [:clip_from, :clip_to, :thumbnail_url, :ad_id, :video_id])
    |> validate_required([:clip_from, :clip_to, :ad_id, :video_id])
    |> foreign_key_constraint(:ad_id)
    |> foreign_key_constraint(:video_id)
  end
end
