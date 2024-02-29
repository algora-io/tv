defmodule Algora.Chat do
  @moduledoc """
  The Chat context.
  """

  import Ecto.Query, warn: false
  alias Algora.Library.Video
  alias Algora.Accounts.User
  alias Algora.Repo

  alias Algora.Chat.Message

  def list_messages(%Video{} = video) do
    # TODO: add limit
    from(m in Message,
      join: u in User,
      on: m.user_id == u.id,
      where: m.video_id == ^video.id,
      select_merge: %{sender_handle: u.handle}
    )
    |> order_by_inserted(:asc)
    |> Repo.replica().all()
  end

  defp order_by_inserted(%Ecto.Query{} = query, direction) when direction in [:asc, :desc] do
    from(s in query, order_by: [{^direction, s.inserted_at}])
  end

  def get_message!(id), do: Repo.replica().get!(Message, id)

  def create_message(attrs \\ %{}) do
    %Message{}
    |> Message.changeset(attrs)
    |> Repo.insert()
  end

  def update_message(%Message{} = message, attrs) do
    message
    |> Message.changeset(attrs)
    |> Repo.update()
  end

  def delete_message(%Message{} = message) do
    Repo.delete(message)
  end

  def change_message(%Message{} = message, attrs \\ %{}) do
    Message.changeset(message, attrs)
  end
end
