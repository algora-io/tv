defmodule AlgoraWeb.AudienceLive do
  use AlgoraWeb, :live_view

  alias Algora.Events

  def render(assigns) do
    ~H"""
    <div class="max-w-4xl mx-auto pt-2 pb-6 px-4 sm:px-6 space-y-6">
      <.header>
        <h1 class="text-3xl font-semibold">Audience</h1>
        <p class="text-base font-medium text-gray-200">View & manage your audience</p>
      </.header>

      <dl class="mt-16 grid grid-cols-1 gap-4 text-center sm:grid-cols-2">
        <div class="flex flex-col bg-white/5 p-8 ring-1 ring-white/15 rounded-lg">
          <dt class="text-sm font-semibold leading-6 text-gray-300">Subscribers</dt>
          <dd class="order-first text-3xl font-semibold tracking-tight text-white">
            <%= length(@subscribers) %>
          </dd>
        </div>
        <div class="flex flex-col bg-white/5 p-8 ring-1 ring-white/15 rounded-lg">
          <dt class="text-sm font-semibold leading-6 text-gray-300">Unique viewers</dt>
          <dd class="order-first text-3xl font-semibold tracking-tight text-white">
            <%= length(@viewers) %>
          </dd>
        </div>
      </dl>

      <div class="pt-6 sm:flex-auto">
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
            :if={subscriber.first_video_id}
            navigate={~p"/#{@current_user.handle}/#{subscriber.first_video_id}"}
            class="truncate ml-auto flex w-[200px]"
          >
            <span class="truncate">
              <%= subscriber.first_video_title %>
            </span>
          </.link>
        </:col>
      </.table>

      <div class="pt-6 sm:flex-auto">
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
            :if={viewer.first_video_id}
            navigate={~p"/#{@current_user.handle}/#{viewer.first_video_id}"}
            class="truncate ml-auto flex w-[200px]"
          >
            <span class="truncate">
              <%= viewer.first_video_title %>
            </span>
          </.link>
        </:col>
      </.table>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    viewers = Events.fetch_unique_viewers(user)
    subscribers = Events.fetch_unique_subscribers(user)

    {:ok,
     socket
     |> assign(:viewers, viewers)
     |> assign(:subscribers, subscribers)}
  end
end
