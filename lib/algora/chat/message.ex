defmodule Algora.Chat.Message do
  use Ecto.Schema
  alias Algora.Accounts.User
  alias Algora.Library.Video
  import Ecto.Changeset

  schema "messages" do
    field :body, :string
    field :sender_handle, :string, virtual: true
    field :channel_id, :integer, virtual: true
    belongs_to :user, User
    belongs_to :video, Video

    timestamps()
  end

  @doc false
  def changeset(message, attrs) do
    message
    |> cast(attrs, [:body])
    |> validate_required([:body])
  end

  def put_user(%Ecto.Changeset{} = changeset, %User{} = user) do
    put_assoc(changeset, :user, user)
  end

  def put_video(%Ecto.Changeset{} = changeset, %Video{} = video) do
    put_assoc(changeset, :video, video)
  end
end
