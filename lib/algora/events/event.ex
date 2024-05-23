defmodule Algora.Events.Event do
  use Ecto.Schema
  import Ecto.Changeset

  schema "events" do
    field :actor_id, :string
    field :user_id, :integer
    field :video_id, :integer
    field :channel_id, :integer
    field :name, Ecto.Enum, values: [:subscribed, :unsubscribed, :watched]

    timestamps()
  end

  def changeset(event, attrs) do
    event
    |> cast(attrs, [:actor_id, :user_id, :video_id, :channel_id, :name])
    |> validate_required([:actor_id, :name])
  end
end
