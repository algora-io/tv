defmodule Algora.Shows.Show do
  use Ecto.Schema
  import Ecto.Changeset

  schema "shows" do
    field :title, :string
    field :description, :string
    field :slug, :string
    field :scheduled_for, :naive_datetime
    field :image_url, :string
    field :url, :string
    field :user_id, :id

    timestamps()
  end

  @doc false
  def changeset(show, attrs) do
    show
    |> cast(attrs, [:title, :slug, :scheduled_for, :image_url])
    |> validate_required([:title, :slug, :scheduled_for, :image_url])
  end
end
