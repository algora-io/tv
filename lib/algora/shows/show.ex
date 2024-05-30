defmodule Algora.Shows.Show do
  use Ecto.Schema
  import Ecto.Changeset

  alias Algora.Accounts.User

  schema "shows" do
    field :title, :string
    field :description, :string
    field :slug, :string
    field :scheduled_for, :naive_datetime
    field :image_url, :string
    field :og_image_url, :string
    field :url, :string
    field :ordering, :integer
    field :channel_handle, :string, virtual: true
    field :channel_name, :string, virtual: true
    field :channel_avatar_url, :string, virtual: true
    field :channel_twitter_url, :string, virtual: true

    belongs_to :user, User

    timestamps()
  end

  @doc false
  def changeset(show, attrs) do
    show
    |> cast(attrs, [:title, :description, :slug, :scheduled_for, :image_url, :url])
    |> validate_required([:title, :slug])
  end
end
