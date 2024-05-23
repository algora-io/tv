defmodule Algora.Chat do
  @moduledoc """
  The Chat context.
  """

  import Ecto.Query, warn: false
  alias Algora.Library.Video
  alias Algora.Accounts.{User, Entity}
  alias Algora.{Repo, Accounts}

  alias Algora.Chat.{Message, Events}

  @pubsub Algora.PubSub

  def subscribe_to_room(%Video{} = video) do
    Phoenix.PubSub.subscribe(@pubsub, topic(video.id))
  end

  def list_messages(%Video{} = video) do
    # TODO: add limit
    from(m in Message,
      join: e in Entity,
      on: m.entity_id == e.id,
      left_join: u in User,
      on: m.user_id == u.id,
      join: v in Video,
      on: m.video_id == v.id,
      join: c in User,
      on: c.id == v.user_id,
      select_merge: %{
        sender_handle: coalesce(u.handle, e.handle),
        channel_id: c.id
      },
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
      join: e in Entity,
      on: m.entity_id == e.id,
      left_join: u in User,
      on: m.user_id == u.id,
      join: v in Video,
      on: m.video_id == v.id,
      join: c in User,
      on: c.id == v.user_id,
      select_merge: %{
        sender_handle: coalesce(u.handle, e.handle),
        channel_id: c.id
      },
      where: m.id == ^id
    )
    |> Repo.one!()
  end

  def create_message(%User{} = user, %Video{} = video, attrs) do
    entity = Accounts.get_or_create_entity!(user)

    %Message{}
    |> Message.changeset(attrs)
    |> Message.put_entity(entity)
    |> Message.put_user(user)
    |> Message.put_video(video)
    |> Repo.insert()
  end

  def create_message(%Entity{} = entity, %Video{} = video, attrs) do
    %Message{}
    |> Message.changeset(attrs)
    |> Message.put_entity(entity)
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

  defp topic(video_id) when is_integer(video_id), do: "room:#{video_id}"

  defp broadcast!(topic, msg) do
    Phoenix.PubSub.broadcast!(@pubsub, topic, {__MODULE__, msg})
  end

  def broadcast_message_deleted!(message) do
    broadcast!(topic(message.video_id), %Events.MessageDeleted{message: message})
  end

  def broadcast_message_sent!(message) do
    broadcast!(topic(message.video_id), %Events.MessageSent{message: message})
  end
end
