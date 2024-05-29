defmodule AlgoraWeb.SubscriptionsLive do
  use AlgoraWeb, :live_view

  alias Algora.Events

  def render(assigns) do
    ~H"""
    <div class="max-w-4xl mx-auto pt-2 pb-6 px-4 sm:px-6 space-y-6">
      <.header>
        <h1 class="text-3xl font-semibold">Subscriptions</h1>
        <p class="text-base font-medium text-gray-200">View & manage your subscriptions</p>
      </.header>
      <.table id="videos" rows={@subscriptions} class="-mt-8">
        <:col :let={subscription}>
          <.link navigate={~p"/#{subscription.user_handle}"} class="flex items-center">
            <div class="h-11 w-11 flex-shrink-0">
              <img
                class="h-11 w-11 rounded-full"
                src={subscription.user_avatar_url}
                alt={subscription.user_display_name}
              />
            </div>
            <div class="ml-4 leading-none">
              <div class="font-medium text-white"><%= subscription.user_display_name %></div>
              <div class="mt-1 text-gray-400">@<%= subscription.user_handle %></div>
            </div>
          </.link>
        </:col>
        <:col :let={subscription}>
          <div class="flex justify-end">
            <.button
              :if={@current_user}
              phx-click="unsubscribe"
              phx-value-id={subscription.channel_id}
              class="flex flex-col justify-end"
            >
              Unsubscribe
            </.button>
          </div>
        </:col>
      </.table>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    subscriptions = Events.fetch_subscriptions(user)

    {:ok,
     socket
     |> assign(:subscriptions, subscriptions)}
  end

  def handle_event("unsubscribe", %{"id" => id}, socket) do
    Events.unsubscribe(socket.assigns.current_user, String.to_integer(id))
    subscriptions = Events.fetch_subscriptions(socket.assigns.current_user)

    {:noreply,
     socket
     |> assign(:subscriptions, subscriptions)}
  end
end
