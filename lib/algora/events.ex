defmodule Algora.Events do
  import Ecto.Query

  alias Algora.{Repo}
  alias Algora.Library.Video
  alias Algora.Events.Event
  alias Algora.Accounts.{User, Identity}

  def unsubscribe(user, channel_id) do
    %Event{
      actor_id: "user_#{user.id}",
      user_id: user.id,
      channel_id: channel_id,
      name: :unsubscribed
    }
    |> Event.changeset(%{})
    |> Repo.insert()
  end

  def toggle_subscription_event(user, show) do
    name = if subscribed?(user, show), do: :unsubscribed, else: :subscribed

    %Event{
      actor_id: "user_#{user.id}",
      user_id: user.id,
      show_id: show.id,
      channel_id: show.user_id,
      name: name
    }
    |> Event.changeset(%{})
    |> Repo.insert()
  end

  def toggle_rsvp_event(user, show) do
    name = if rsvpd?(user, show), do: :unrsvpd, else: :rsvpd

    %Event{
      actor_id: "user_#{user.id}",
      user_id: user.id,
      show_id: show.id,
      channel_id: show.user_id,
      name: name
    }
    |> Event.changeset(%{})
    |> Repo.insert()
  end

  def subscribed?(nil, _show), do: false

  def subscribed?(user, show) do
    event =
      from(
        e in Event,
        where:
          e.channel_id == ^show.user_id and
            e.user_id == ^user.id and
            (e.name == :subscribed or
               e.name == :unsubscribed),
        order_by: [desc: e.inserted_at],
        limit: 1
      )
      |> Repo.one()

    event && event.name == :subscribed
  end

  def rsvpd?(nil, _show), do: false

  def rsvpd?(user, show) do
    event =
      from(
        e in Event,
        where:
          e.channel_id == ^show.user_id and
            e.user_id == ^user.id and
            (e.name == :rsvpd or
               e.name == :unrsvpd),
        order_by: [desc: e.inserted_at],
        limit: 1
      )
      |> Repo.one()

    event && event.name == :rsvpd
  end

  def fetch_attendees(show) do
    # Get the latest relevant events (:rsvpd and :unrsvpd) for each user
    latest_events_query =
      from(e in Event,
        where: e.channel_id == ^show.user_id and e.name in [:rsvpd, :unrsvpd],
        order_by: [desc: e.inserted_at],
        distinct: e.user_id
      )

    # Join user data and filter for :rsvpd events
    from(e in subquery(latest_events_query),
      join: u in User,
      on: e.user_id == u.id,
      join: i in Identity,
      on: i.user_id == u.id and i.provider == "github",
      select_merge: %{
        user_handle: u.handle,
        user_display_name: coalesce(u.name, u.handle),
        user_email: u.email,
        user_avatar_url: u.avatar_url,
        user_github_handle: i.provider_login
      },
      where: e.name == :rsvpd,
      order_by: [desc: e.inserted_at, desc: e.id]
    )
    |> Repo.all()
  end

  def fetch_unique_viewers(user) do
    subquery_first_watched =
      from(e in Event,
        where: e.channel_id == ^user.id and e.name in [:watched, :subscribed],
        order_by: [asc: e.inserted_at],
        distinct: e.user_id
      )

    from(e in subquery(subquery_first_watched),
      join: u in User,
      on: e.user_id == u.id,
      join: i in Identity,
      on: i.user_id == u.id and i.provider == "github",
      left_join: v in Video,
      on: e.video_id == v.id,
      select_merge: %{
        user_handle: u.handle,
        user_display_name: coalesce(u.name, u.handle),
        user_email: u.email,
        user_avatar_url: u.avatar_url,
        user_github_handle: i.provider_login,
        first_video_id: e.video_id,
        first_video_title: v.title
      },
      distinct: e.user_id,
      order_by: [desc: e.inserted_at, desc: e.id]
    )
    |> Repo.all()
  end

  def fetch_unique_subscribers(user) do
    # Get the latest relevant events (:subscribed and :unsubscribed) for each user
    latest_events_query =
      from(e in Event,
        where: e.channel_id == ^user.id and e.name in [:subscribed, :unsubscribed],
        order_by: [desc: e.inserted_at],
        distinct: e.user_id
      )

    # Join user data and filter for :subscribed events
    from(e in subquery(latest_events_query),
      join: u in User,
      on: e.user_id == u.id,
      join: i in Identity,
      on: i.user_id == u.id and i.provider == "github",
      left_join: v in Video,
      on: e.video_id == v.id,
      select_merge: %{
        user_handle: u.handle,
        user_display_name: coalesce(u.name, u.handle),
        user_email: u.email,
        user_avatar_url: u.avatar_url,
        user_github_handle: i.provider_login,
        first_video_id: e.video_id,
        first_video_title: v.title
      },
      where: e.name == :subscribed,
      order_by: [desc: e.inserted_at, desc: e.id]
    )
    |> Repo.all()
  end

  def fetch_subscriptions(user) do
    # Get the latest relevant events (:subscribed and :unsubscribed) for each user
    latest_events_query =
      from(e in Event,
        where: e.user_id == ^user.id and e.name in [:subscribed, :unsubscribed],
        order_by: [desc: e.inserted_at],
        distinct: e.channel_id
      )

    # Join user data and filter for :subscribed events
    from(e in subquery(latest_events_query),
      join: u in User,
      on: e.channel_id == u.id,
      select_merge: %{
        user_handle: u.handle,
        user_display_name: coalesce(u.name, u.handle),
        user_avatar_url: u.avatar_url
      },
      where: e.name == :subscribed,
      order_by: [desc: e.inserted_at, desc: e.id]
    )
    |> Repo.all()
  end
end
