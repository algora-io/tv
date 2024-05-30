defmodule AlgoraWeb.SubscriptionsLive do
  use AlgoraWeb, :live_view

  alias Algora.Events

  def render(assigns) do
    ~H"""
    <div class="max-w-5xl mx-auto pt-2 pb-6 px-4 sm:px-6 space-y-6">
      <.header>
        <h1 class="text-3xl font-semibold">Subscriptions</h1>
        <p class="text-base font-medium text-gray-200">View & manage your subscriptions</p>
      </.header>

      <ul role="list" class="grid grid-cols-1 gap-6 sm:grid-cols-2 md:grid-cols-3">
        <li
          :for={subscription <- @subscriptions}
          class="col-span-1 flex flex-col rounded-2xl overflow-hidden bg-white/5 ring-1 ring-white/20 text-center shadow-lg relative group"
        >
          <img
            class="mx-auto absolute inset-0 flex-shrink-0 object-cover h-full w-full"
            src={subscription.user_avatar_url}
            alt=""
          />
          <div class="absolute h-full w-full inset-0 bg-gradient-to-b from-transparent to-80% to-gray-950/80" />
          <div class="absolute inset-0 bg-purple-700/10" />
          <div class="relative">
            <div class="flex flex-1 flex-col min-h-[16rem]">
              <h3 class="mt-auto text-2xl font-semibold text-white [text-shadow:#000_10px_5px_10px]">
                <%= subscription.user_display_name %>
              </h3>
              <dl class="mt-1 flex flex-col justify-between px-2">
                <dt class="sr-only">Bio</dt>
                <dd class="text-sm text-gray-300 font-medium line-clamp-1">
                  <%= subscription.user_meta["user"]["bio"] ||
                    subscription.user_meta["user"]["company"] || "@#{subscription.user_handle}" %>
                </dd>
              </dl>
              <div class="-mt-2 group-hover:mt-2 grid grid-cols-2 divide-white/20 divide-x border-t border-transparent group-hover:border-white/20 transition-all">
                <.button class="opacity-0 rounded-none h-0 group-hover:opacity-100 group-hover:h-10 transition-all text-sm bg-gray-950/50 hover:bg-gray-950/75 text-white">
                  <.link navigate={~p"/#{subscription.user_handle}"} class="relative">
                    Watch
                  </.link>
                </.button>
                <.button
                  phx-click="unsubscribe"
                  phx-value-id={subscription.channel_id}
                  class="opacity-0 rounded-none h-0 group-hover:opacity-100 group-hover:h-10 transition-all text-sm bg-gray-950/50 hover:bg-gray-950/75 text-white"
                >
                  Unsubscribe
                </.button>
              </div>
            </div>
          </div>
        </li>
      </ul>
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
