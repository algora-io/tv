defmodule Algora.Ads.Impression do
  use Ecto.Schema
  import Ecto.Changeset

  schema "ad_impressions" do
    field :duration, :integer
    field :viewers_count, :integer
    field :ad_id, :id
    field :video_id, :id

    timestamps()
  end

  @doc false
  def changeset(impression, attrs) do
    impression
    |> cast(attrs, [:duration, :viewers_count, :ad_id, :video_id])
    |> validate_required([:duration, :viewers_count, :ad_id])
  end
end
