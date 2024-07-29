defmodule Algora.Ads.Impression do
  use Ecto.Schema
  import Ecto.Changeset

  schema "ad_impressions" do
    field :duration, :integer
    field :concurrent_viewers, :integer
    field :ad_id, :id
    field :video_id, :id

    timestamps()
  end

  @doc false
  def changeset(impression, attrs) do
    impression
    |> cast(attrs, [:duration, :concurrent_viewers])
    |> validate_required([:duration, :concurrent_viewers])
  end
end
