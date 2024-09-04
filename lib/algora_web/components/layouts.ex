defmodule AlgoraWeb.Layouts do
  use AlgoraWeb, :html

  embed_templates "layouts/*"

  attr :id, :string
  attr :users, :list

  def sidebar_active_users(assigns) do
    duplicated_users = assigns.users ++ assigns.users ++ assigns.users ++ assigns.users ++ assigns.users ++ assigns.users
    ~H"""
    <div :if={length(@users) > 0}>
      <ul class="mt-4 space-y-5" role="group" aria-labelledby={@id}>
        <%= for user <- duplicated_users do %>
          <li class="relative col-span-1 flex shadow-sm rounded-md overflow-hidden">
            <.link
              navigate={channel_path(user)}
              class="px-1 pr-3 flex-1 flex items-center justify-between rounded-r-md truncate"
            >
              <img
                class="w-10 h-10 flex-shrink-0 flex items-center justify-center rounded-full bg-purple-300"
                src={user.avatar_url}
                alt={user.handle}
              />
              <div class="flex-1 flex flex-col justify-between text-gray-50 text-sm font-medium hover:text-gray-300 pl-3">
                <div class="flex-1 py-1 text-sm truncate">
                  <%= user.handle %>
                </div>
              </div>
              <span class="w-2.5 h-2.5 bg-red-500 rounded-full" aria-hidden="true" />
              &nbsp;&nbsp;<p>Live</p>
            </.link>
          </li>
        <% end %>
      </ul>
    </div>
    """
  end

  attr :id, :string
  attr :current_user, :any
  attr :active_tab, :atom

  def sidebar_nav_links(assigns) do
    ~H"""
    <div class="space-y-1">
      <.link
        navigate="/"
        class={
            "text-gray-200 hover:text-gray-50 group flex items-center px-2 py-2 text-sm font-medium rounded-md #{if @active_tab == :home, do: "bg-gray-800", else: "hover:bg-gray-900"}"
          }
        aria-current={if @active_tab == :home, do: "true", else: "false"}
      >
        <svg
          xmlns="http://www.w3.org/2000/svg"
          class="text-gray-400 group-hover:text-gray-300 mr-3 flex-shrink-0 h-6 w-6"
          width="24"
          height="24"
          viewBox="0 0 24 24"
          stroke-width="1.5"
          stroke="currentColor"
          fill="none"
          stroke-linecap="round"
          stroke-linejoin="round"
        >
          <path stroke="none" d="M0 0h24v24H0z" fill="none" /><path d="M5 12l-2 0l9 -9l9 9l-2 0" /><path d="M5 12v7a2 2 0 0 0 2 2h10a2 2 0 0 0 2 -2v-7" /><path d="M9 21v-6a2 2 0 0 1 2 -2h2a2 2 0 0 1 2 2v6" />
        </svg>
        Home
      </.link>
      <.link
        navigate={channel_path(@current_user)}
        class={
            "text-gray-200 hover:text-gray-50 group flex items-center px-2 py-2 text-sm font-medium rounded-md #{if @active_tab == :channel, do: "bg-gray-800", else: "hover:bg-gray-900"}"
          }
        aria-current={if @active_tab == :channel, do: "true", else: "false"}
      >
        <svg
          xmlns="http://www.w3.org/2000/svg"
          class="text-gray-400 group-hover:text-gray-300 mr-3 flex-shrink-0 h-6 w-6"
          width="24"
          height="24"
          viewBox="0 0 24 24"
          stroke-width="1.5"
          stroke="currentColor"
          fill="none"
          stroke-linecap="round"
          stroke-linejoin="round"
        >
          <path stroke="none" d="M0 0h24v24H0z" fill="none" /><path d="M12 13a3 3 0 1 0 0 -6a3 3 0 0 0 0 6z" /><path d="M12 3c7.2 0 9 1.8 9 9s-1.8 9 -9 9s-9 -1.8 -9 -9s1.8 -9 9 -9z" /><path d="M6 20.05v-.05a4 4 0 0 1 4 -4h4a4 4 0 0 1 4 4v.05" />
        </svg>
        Channel
      </.link>
      <.link
        navigate="/channel/studio"
        class={
            "text-gray-200 hover:text-gray-50 group flex items-center px-2 py-2 text-sm font-medium rounded-md #{if @active_tab == :studio, do: "bg-gray-800", else: "hover:bg-gray-900"}"
          }
        aria-current={if @active_tab == :studio, do: "true", else: "false"}
      >
        <svg
          xmlns="http://www.w3.org/2000/svg"
          class="text-gray-400 group-hover:text-gray-300 mr-3 flex-shrink-0 h-6 w-6"
          width="24"
          height="24"
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          stroke-width="2"
          stroke-linecap="round"
          stroke-linejoin="round"
        >
          <path stroke="none" d="M0 0h24v24H0z" fill="none" /><path d="M15 10l4.553 -2.276a1 1 0 0 1 1.447 .894v6.764a1 1 0 0 1 -1.447 .894l-4.553 -2.276v-4z" /><path d="M3 6m0 2a2 2 0 0 1 2 -2h8a2 2 0 0 1 2 2v8a2 2 0 0 1 -2 2h-8a2 2 0 0 1 -2 -2z" />
        </svg>
        Studio
      </.link>
      <.link
        navigate="/subscriptions"
        class={
            "text-gray-200 hover:text-gray-50 group flex items-center px-2 py-2 text-sm font-medium rounded-md #{if @active_tab == :studio, do: "bg-gray-800", else: "hover:bg-gray-900"}"
          }
        aria-current={if @active_tab == :studio, do: "true", else: "false"}
      >
        <svg
          xmlns="http://www.w3.org/2000/svg"
          width="24"
          height="24"
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          stroke-width="2"
          stroke-linecap="round"
          stroke-linejoin="round"
          class="text-gray-400 group-hover:text-gray-300 mr-3 flex-shrink-0 h-6 w-6"
        >
          <path stroke="none" d="M0 0h24v24H0z" fill="none" /><path d="M19.5 12.572l-7.5 7.428l-7.5 -7.428a5 5 0 1 1 7.5 -6.566a5 5 0 1 1 7.5 6.572" />
        </svg>
        Subscriptions
      </.link>
      <.link
        navigate={~p"/channel/settings"}
        class={
            "text-gray-200 hover:text-gray-50 group flex items-center px-2 py-2 text-sm font-medium rounded-md #{if @active_tab == :settings, do: "bg-gray-800", else: "hover:bg-gray-900"}"
          }
        aria-current={if @active_tab == :settings, do: "true", else: "false"}
      >
        <svg
          xmlns="http://www.w3.org/2000/svg"
          class="text-gray-400 group-hover:text-gray-300 mr-3 flex-shrink-0 h-6 w-6"
          width="24"
          height="24"
          viewBox="0 0 24 24"
          stroke-width="1.5"
          stroke="currentColor"
          fill="none"
          stroke-linecap="round"
          stroke-linejoin="round"
        >
          <path stroke="none" d="M0 0h24v24H0z" fill="none" /><path d="M10.325 4.317c.426 -1.756 2.924 -1.756 3.35 0a1.724 1.724 0 0 0 2.573 1.066c1.543 -.94 3.31 .826 2.37 2.37a1.724 1.724 0 0 0 1.065 2.572c1.756 .426 1.756 2.924 0 3.35a1.724 1.724 0 0 0 -1.066 2.573c.94 1.543 -.826 3.31 -2.37 2.37a1.724 1.724 0 0 0 -2.572 1.065c-.426 1.756 -2.924 1.756 -3.35 0a1.724 1.724 0 0 0 -2.573 -1.066c-1.543 .94 -3.31 -.826 -2.37 -2.37a1.724 1.724 0 0 0 -1.065 -2.572c-1.756 -.426 -1.756 -2.924 0 -3.35a1.724 1.724 0 0 0 1.066 -2.573c-.94 -1.543 .826 -3.31 2.37 -2.37c1 .608 2.296 .07 2.572 -1.065z" /><path d="M9 12a3 3 0 1 0 6 0a3 3 0 0 0 -6 0" />
        </svg>
        Settings
      </.link>
    </div>
    """
  end

  attr :id, :string
  attr :current_user, :any

  def sidebar_account_dropdown(assigns) do
    ~H"""
    <.dropdown id={@id}>
      <:img src={@current_user.avatar_url} alt={@current_user.handle} />
      <:title><%= @current_user.name %></:title>
      <:subtitle>@<%= @current_user.handle %></:subtitle>
      <:link navigate={channel_path(@current_user)}>Channel</:link>
      <:link navigate={~p"/channel/studio"}>Studio</:link>
      <:link navigate={~p"/subscriptions"}>Subscriptions</:link>
      <:link navigate={~p"/channel/settings"}>Settings</:link>
      <:link href={~p"/auth/logout"} method={:delete}>Sign out</:link>
    </.dropdown>
    """
  end
end
