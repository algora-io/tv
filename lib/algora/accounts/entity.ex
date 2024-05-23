defmodule Algora.Accounts.Entity do
  use Ecto.Schema
  import Ecto.Changeset

  alias Algora.Accounts.User

  schema "entities" do
    field :name, :string
    field :handle, :string
    field :avatar_url, :string
    field :platform, :string
    field :platform_id, :string
    field :platform_meta, :map, default: %{}

    belongs_to :user, User

    timestamps()
  end

  @doc false
  def changeset(entity, attrs) do
    entity
    |> cast(attrs, [
      :user_id,
      :name,
      :handle,
      :avatar_url,
      :platform,
      :platform_id,
      :platform_meta
    ])
    |> validate_required([:handle, :platform, :platform_id, :platform_meta])
  end
end
