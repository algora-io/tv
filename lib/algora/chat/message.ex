defmodule Algora.Chat.Message do
  use Ecto.Schema
  alias Algora.Accounts
  alias Algora.Library
  import Ecto.Changeset

  schema "messages" do
    field :body, :string
    field :sender_handle, :string, virtual: true
    belongs_to :user, Accounts.User
    belongs_to :video, Library.Video

    timestamps()
  end

  @doc false
  def changeset(message, attrs) do
    message
    |> cast(attrs, [:body])
    |> validate_required([:body])
  end
end
