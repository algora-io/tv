defmodule AlgoraWeb.AudienceLive do
  use AlgoraWeb, :live_view
  import Ecto.Query, warn: false

  alias Algora.Accounts.{User, Identity}
  alias Algora.Events.Event
  alias Algora.Library.Video
  alias Algora.Repo

  def render(assigns) do
    ~H"""
    <div class="max-w-4xl mx-auto pt-2 pb-6 px-4 sm:px-6 space-y-6">
      <.header>
        <h1 class="text-3xl font-semibold">Audience</h1>
        <p class="text-base font-medium text-gray-200">View & manage your audience</p>
      </.header>

      <dl class="mt-16 grid grid-cols-1 gap-4 text-center sm:grid-cols-2">
        <div class="flex flex-col bg-white/5 p-8 ring-1 ring-white/15 rounded-lg">
          <dt class="text-sm font-semibold leading-6 text-gray-300">Unique viewers</dt>
          <dd class="order-first text-3xl font-semibold tracking-tight text-white">
            <%= length(@viewers) %>
          </dd>
        </div>
        <div class="flex flex-col bg-white/5 p-8 ring-1 ring-white/15 rounded-lg">
          <dt class="text-sm font-semibold leading-6 text-gray-300">Subscribers</dt>
          <dd class="order-first text-3xl font-semibold tracking-tight text-white">
            <%= length(@subscribers) %>
          </dd>
        </div>
      </dl>

      <div class="sm:flex-auto">
        <h2 class="text-base font-semibold leading-6 text-white">Viewers</h2>
        <p class="text-sm text-gray-200">
          List of users who tuned in to your streams
        </p>
      </div>
      <.table id="videos" rows={@viewers} class="-mt-8">
        <:col :let={viewer}>
          <.link
            navigate={"https://github.com/#{viewer.user_github_handle}"}
            class="flex items-center"
          >
            <div class="h-11 w-11 flex-shrink-0">
              <img
                class="h-11 w-11 rounded-full"
                src={viewer.user_avatar_url}
                alt={viewer.user_display_name}
              />
            </div>
            <div class="ml-4 leading-none">
              <div class="font-medium text-white"><%= viewer.user_display_name %></div>
              <div class="mt-1 text-gray-400">@<%= viewer.user_handle %></div>
            </div>
          </.link>
        </:col>
        <:col :let={viewer}>
          <div class="text-gray-100"><%= viewer.user_email %></div>
        </:col>
        <:col :let={viewer}>
          <.link
            navigate={~p"/#{@current_user.handle}/#{viewer.first_video_id}"}
            class="truncate ml-auto flex w-[200px]"
          >
            <span class="truncate">
              <%= viewer.first_video_title %>
            </span>
          </.link>
        </:col>
      </.table>

      <div class="sm:flex-auto">
        <h2 class="text-base font-semibold leading-6 text-white">Subscribers</h2>
        <p class="text-sm text-gray-200">
          List of users who subscribed to your content
        </p>
      </div>
      <.table id="videos" rows={@subscribers} class="-mt-8">
        <:col :let={subscriber}>
          <.link
            navigate={"https://github.com/#{subscriber.user_github_handle}"}
            class="flex items-center"
          >
            <div class="h-11 w-11 flex-shrink-0">
              <img
                class="h-11 w-11 rounded-full"
                src={subscriber.user_avatar_url}
                alt={subscriber.user_display_name}
              />
            </div>
            <div class="ml-4 leading-none">
              <div class="font-medium text-white"><%= subscriber.user_display_name %></div>
              <div class="mt-1 text-gray-400">@<%= subscriber.user_handle %></div>
            </div>
          </.link>
        </:col>
        <:col :let={subscriber}>
          <div class="text-gray-100"><%= subscriber.user_email %></div>
        </:col>
        <:col :let={subscriber}>
          <.link
            navigate={~p"/#{@current_user.handle}/#{subscriber.first_video_id}"}
            class="truncate ml-auto flex w-[200px]"
          >
            <span class="truncate">
              <%= subscriber.first_video_title %>
            </span>
          </.link>
        </:col>
      </.table>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    viewers = fetch_unique_viewers(user)
    subscribers = fetch_unique_subscribers(user)

    {:ok, assign(socket, viewers: viewers, subscribers: subscribers)}
  end

  defp fetch_unique_viewers(user) do
    subquery_first_watched =
      from(e in Event,
        where: e.name in [:watched, :subscribed],
        order_by: [asc: e.inserted_at],
        distinct: e.user_id
      )

    from(e in subquery(subquery_first_watched),
      left_join: u in User,
      on: e.user_id == u.id,
      left_join: i in Identity,
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
      where: not is_nil(u.id) and e.channel_id == ^user.id,
      distinct: e.user_id,
      order_by: [desc: e.inserted_at, desc: e.id]
    )
    |> Repo.all()
  end

  defp fetch_unique_subscribers(user) do
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
      left_join: i in Identity,
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
end
