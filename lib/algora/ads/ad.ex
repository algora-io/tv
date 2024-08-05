defmodule Algora.Ads.Ad do
  use Ecto.Schema
  import Ecto.Changeset

  schema "ads" do
    field :slug, :string
    field :status, Ecto.Enum, values: [:inactive, :active]
    field :verified, :boolean, default: false
    field :website_url, :string
    field :composite_asset_url, :string
    field :asset_url, :string
    field :logo_url, :string
    field :qrcode_url, :string
    field :start_date, :naive_datetime
    field :end_date, :naive_datetime
    field :total_budget, :integer
    field :daily_budget, :integer
    field :tech_stack, {:array, :string}
    field :user_id, :id
    field :border_color, :string

    timestamps()
  end

  @doc false
  def changeset(ad, attrs) do
    ad
    |> cast(attrs, [
      :slug,
      :verified,
      :website_url,
      :composite_asset_url,
      :asset_url,
      :logo_url,
      :qrcode_url,
      :start_date,
      :end_date,
      :total_budget,
      :daily_budget,
      :tech_stack,
      :status,
      :border_color
    ])
    |> validate_required([
      :slug,
      :verified,
      :website_url,
      :composite_asset_url,
      :asset_url,
      :logo_url,
      :qrcode_url,
      :start_date,
      :end_date,
      :total_budget,
      :daily_budget,
      :tech_stack,
      :status
    ])
    |> validate_format(:border_color, ~r/^#([0-9A-F]{3}){1,2}$/i,
      message: "must be a valid hex color code"
    )
    |> unique_constraint(:slug)
  end
end
