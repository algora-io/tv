defmodule Algora.Accounts.Destination do
  use Ecto.Schema
  import Ecto.Changeset

  schema "destinations" do
    field :rtmp_url, :string
    field :stream_key, :string, redact: true
    field :active, :boolean, default: true
    belongs_to :user, Algora.Accounts.User

    timestamps()
  end

  def changeset(destination, attrs) do
    destination
    |> cast(attrs, [:rtmp_url, :stream_key, :active])
    |> validate_required([:rtmp_url, :stream_key])
  end
end
