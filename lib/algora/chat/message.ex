defmodule Algora.Chat.Message do
  use Ecto.Schema
  alias Algora.Accounts.{User, Entity}
  alias Algora.Library.Video
  import Ecto.Changeset

  @derive {Jason.Encoder,
           only: [
             :body,
             :platform,
             :sender_handle,
             :sender_name,
             :sender_avatar_url,
             :inserted_at
           ]}
  schema "messages" do
    field :body, :string
    field :platform_id, :string
    field :platform, :string, virtual: true
    field :sender_handle, :string, virtual: true
    field :sender_name, :string, virtual: true
    field :sender_avatar_url, :string, virtual: true
    field :channel_id, :integer, virtual: true
    belongs_to :entity, Entity
    belongs_to :user, User
    belongs_to :video, Video

    timestamps()
  end

  @doc false
  def changeset(message, attrs) do
    message
    |> cast(attrs, [:body, :platform_id])
    |> validate_required([:body])
  end

  def put_entity(%Ecto.Changeset{} = changeset, %Entity{} = entity) do
    put_assoc(changeset, :entity, entity)
  end

  def put_user(%Ecto.Changeset{} = changeset, %User{} = user) do
    put_assoc(changeset, :user, user)
  end

  def put_video(%Ecto.Changeset{} = changeset, %Video{} = video) do
    put_assoc(changeset, :video, video)
  end
end
