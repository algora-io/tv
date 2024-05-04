defmodule Algora.Chat do
  @moduledoc """
  The Chat context.
  """

  import Ecto.Query, warn: false
  alias Algora.Library.Video
  alias Algora.Accounts.User
  alias Algora.{Repo, Accounts}

  alias Algora.Chat.Message

  def list_messages(%Video{} = video) do
    # TODO: add limit
    from(m in Message,
      join: u in User,
      on: m.user_id == u.id,
      join: v in Video,
      on: m.video_id == v.id,
      join: c in User,
      on: c.id == v.user_id,
      select_merge: %{sender_handle: u.handle, channel_id: c.id},
      where: m.video_id == ^video.id
    )
    |> order_by_inserted(:asc)
    |> Repo.all()
  end

  defp order_by_inserted(%Ecto.Query{} = query, direction) when direction in [:asc, :desc] do
    from(s in query, order_by: [{^direction, s.inserted_at}])
  end

  def can_delete?(%User{} = user, %Message{} = message) do
    user.id == message.channel_id or user.id == message.user_id or Accounts.admin?(user)
  end

  def get_message!(id) do
    from(m in Message,
      join: u in User,
      on: m.user_id == u.id,
      join: v in Video,
      on: m.video_id == v.id,
      join: c in User,
      on: c.id == v.user_id,
      select_merge: %{sender_handle: u.handle, channel_id: c.id},
      where: m.id == ^id
    )
    |> Repo.one!()
  end

  def create_message(%User{} = user, %Video{} = video, attrs \\ %{}) do
    %Message{}
    |> Message.changeset(attrs)
    |> Message.put_user(user)
    |> Message.put_video(video)
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
