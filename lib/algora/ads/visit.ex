defmodule Algora.Ads.Visit do
  use Ecto.Schema
  import Ecto.Changeset

  schema "ad_visits" do

    field :ad_id, :id
    field :video_id, :id

    timestamps()
  end

  @doc false
  def changeset(visit, attrs) do
    visit
    |> cast(attrs, [])
    |> validate_required([])
  end
end
