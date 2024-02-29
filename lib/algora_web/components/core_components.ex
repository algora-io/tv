defmodule AlgoraWeb.CoreComponents do
  use Phoenix.Component
  use AlgoraWeb, :verified_routes

  alias Phoenix.LiveView.JS
  alias Algora.{Accounts, Library}

  def home_path(nil = _current_user), do: "/"
  def home_path(%Accounts.User{} = current_user), do: channel_path(current_user)

  def channel_stream_path(%Accounts.User{} = user) do
    ~p"/#{user.handle}/stream"
  end

  def channel_path(handle) when is_binary(handle) do
    unverified_path(AlgoraWeb.Endpoint, AlgoraWeb.Router, ~p"/#{handle}")
  end

  def channel_path(%Accounts.User{} = current_user) do
    channel_path(current_user.handle)
  end

  def channel_path(%Library.Channel{} = channel) do
    channel_path(channel.handle)
  end

  slot :inner_block

  def connection_status(assigns) do
    ~H"""
    <div
      id="connection-status"
      class="hidden rounded-md bg-red-900 p-4 fixed top-1 right-1 w-96 fade-in-scale z-50"
      js-show={show("#connection-status")}
      js-hide={hide("#connection-status")}
    >
      <div class="flex">
        <div class="flex-shrink-0">
          <svg
            class="animate-spin -ml-1 mr-3 h-5 w-5 text-red-100"
            xmlns="http://www.w3.org/2000/svg"
            fill="none"
            viewBox="0 0 24 24"
            aria-hidden="true"
          >
            <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4">
            </circle>
            <path
              class="opacity-75"
              fill="currentColor"
              d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
            >
            </path>
          </svg>
        </div>
        <div class="ml-3">
          <p class="text-sm font-medium text-red-100" role="alert">
            <%= render_slot(@inner_block) %>
          </p>
        </div>
      </div>
    </div>
    """
  end

  attr :class, :string, default: nil

  def logo(assigns) do
    ~H"""
    <.link navigate="/" aria-label="Algora TV">
      <svg
        xmlns="http://www.w3.org/2000/svg"
        viewBox="0 0 100.14 39.42"
        class={@class || "h-auto w-20 fill-white"}
      >
        <g>
          <path d="M19.25 9v19.24H16v-2.37a9.63 9.63 0 1 1 0-14.51V9ZM16 18.63A6.32 6.32 0 1 0 9.64 25 6.32 6.32 0 0 0 16 18.63ZM22.29 0h3.29v28.24h-3.29ZM47.6 34.27v.07a5.41 5.41 0 0 1-.69 2.52 4.78 4.78 0 0 1-1.39 1.54 5.61 5.61 0 0 1-3.25 1H34a5.21 5.21 0 0 1-3.88-1.5 6.25 6.25 0 0 1-1.53-4.2l3.29.11a2.58 2.58 0 0 0 .62 1.83 2 2 0 0 0 1.5.47h8.29c1.68 0 2-1.1 2-1.75a2 2 0 0 0-2-1.76h-8.2a5.35 5.35 0 0 1-5.52-5.51 6.07 6.07 0 0 1 1.24-3.62 9.5 9.5 0 0 1-1.31-4.86A9.62 9.62 0 0 1 38.11 9a9.72 9.72 0 0 1 5.37 1.61A5.78 5.78 0 0 1 47.53 9v3.28a2.54 2.54 0 0 0-1.72.63 9.67 9.67 0 0 1 1.86 5.7 9.79 9.79 0 0 1-5.44 8.7 10 10 0 0 1-4.16.91 9.75 9.75 0 0 1-6.07-2.1 3 3 0 0 0-.18.95 2.08 2.08 0 0 0 2.23 2.27h8.18a5.61 5.61 0 0 1 3.25 1.05 5.45 5.45 0 0 1 2.12 3.88ZM31.78 18.63a6.46 6.46 0 0 0 .84 3.15 5.88 5.88 0 0 0 1.43 1.71A6.34 6.34 0 0 0 38.11 25a6.26 6.26 0 0 0 6.32-6.32 6.27 6.27 0 0 0-2.16-4.71 6.2 6.2 0 0 0-4.16-1.61 6.35 6.35 0 0 0-6.33 6.27ZM68.54 18.63A9.63 9.63 0 1 1 58.93 9a9.62 9.62 0 0 1 9.61 9.63Zm-9.61-6.32a6.32 6.32 0 1 0 6.32 6.32 6.35 6.35 0 0 0-6.32-6.32ZM80.35 14.1h-3.28a1.9 1.9 0 0 0-.4-1.31 2 2 0 0 0-1.28-.48 1.83 1.83 0 0 0-2 1.57v14.36h-3.27V9h3.29v.4a5.24 5.24 0 0 1 1.9-.4 5.47 5.47 0 0 1 3.62 1.35 5 5 0 0 1 1.42 3.75ZM100.14 9v19.24h-3.29v-2.37a9.63 9.63 0 1 1 0-14.51V9Zm-3.29 9.64A6.32 6.32 0 1 0 90.53 25a6.32 6.32 0 0 0 6.32-6.37Z">
          </path>
        </g>
      </svg>
    </.link>
    """
  end

  attr :flash, :map
  attr :kind, :atom

  def flash(%{kind: :error} = assigns) do
    ~H"""
    <div
      :if={msg = Phoenix.Flash.get(@flash, @kind)}
      id="flash"
      class="rounded-md bg-red-900 p-4 fixed top-1 right-1 w-96 fade-in-scale z-50"
      phx-click={
        JS.push("lv:clear-flash")
        |> JS.remove_class("fade-in-scale", to: "#flash")
        |> hide("#flash")
      }
      phx-hook="Flash"
    >
      <div class="flex justify-between items-center space-x-3 text-red-200">
        <Heroicons.exclamation_circle solid class="w-5 h-5" />
        <p class="flex-1 text-sm font-medium" role="alert">
          <%= msg %>
        </p>
        <button
          type="button"
          class="inline-flex bg-red-900 rounded-md p-1.5 text-red-400 hover:bg-red-800 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-offset-red-900 focus:ring-red-300"
        >
          <Heroicons.x_mark solid class="w-4 h-4" />
        </button>
      </div>
    </div>
    """
  end

  def flash(%{kind: :info} = assigns) do
    ~H"""
    <div
      :if={msg = Phoenix.Flash.get(@flash, @kind)}
      id="flash"
      class="rounded-md bg-green-900 p-4 fixed top-1 right-1 w-96 fade-in-scale z-50"
      phx-click={JS.push("lv:clear-flash") |> JS.remove_class("fade-in-scale") |> hide("#flash")}
      phx-value-key="info"
      phx-hook="Flash"
    >
      <div class="flex justify-between items-center space-x-3 text-green-200">
        <Heroicons.check_circle solid class="w-5 h-5" />
        <p class="flex-1 text-sm font-medium" role="alert">
          <%= msg %>
        </p>
        <button
          type="button"
          class="inline-flex bg-green-900 rounded-md p-1.5 text-green-400 hover:bg-green-800 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-offset-green-900 focus:ring-green-300"
        >
          <Heroicons.x_mark solid class="w-4 h-4" />
        </button>
      </div>
    </div>
    """
  end

  def spinner(assigns) do
    ~H"""
    <svg
      class="inline-block animate-spin h-2.5 w-2.5 text-gray-500"
      xmlns="http://www.w3.org/2000/svg"
      fill="none"
      viewBox="0 0 24 24"
      aria-hidden="true"
    >
      <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4">
      </circle>
      <path
        class="opacity-75"
        fill="currentColor"
        d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
      >
      </path>
    </svg>
    """
  end

  @doc """
  Returns a button triggered dropdown with aria keyboard and focus supporrt.

  Accepts the follow slots:

    * `:id` - The id to uniquely identify this dropdown
    * `:img` - The optional img to show beside the button title
    * `:title` - The button title
    * `:subtitle` - The button subtitle

  ## Examples

      <.dropdown id={@id}>
        <:img src={@current_user.avatar_url} alt={@current_user.handle}/>
        <:title><%= @current_user.name %></:title>
        <:subtitle>@<%= @current_user.handle %></:subtitle>

        <:link navigate={channel_path(@current_user)}>View Channel</:link>
        <:link navigate={~p"/channel/settings"}Settings</:link>
      </.dropdown>
  """
  attr :id, :string, required: true

  slot :img do
    attr :src, :string
    attr :alt, :string
  end

  slot :title
  slot :subtitle

  slot :link do
    attr :navigate, :string
    attr :href, :string
    attr :method, :any
  end

  def dropdown(assigns) do
    ~H"""
    <!-- User account dropdown -->
    <div class="px-3 mt-6 w-full relative inline-block text-left">
      <div>
        <button
          id={@id}
          type="button"
          class="group w-full bg-gray-800 rounded-md px-3.5 py-2 text-sm text-left font-medium text-gray-200 hover:bg-gray-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-offset-gray-800 focus:ring-purple-400"
          phx-click={show_dropdown("##{@id}-dropdown")}
          phx-hook="Menu"
          data-active-class="bg-gray-800"
          aria-haspopup="true"
        >
          <span class="flex w-full justify-between items-center">
            <span class="flex min-w-0 items-center justify-between space-x-3">
              <%= for img <- @img do %>
                <img
                  class="w-10 h-10 bg-gray-600 rounded-full flex-shrink-0"
                  {assigns_to_attributes(img)}
                />
              <% end %>
              <span class="flex-1 flex flex-col min-w-0">
                <span class="text-gray-50 text-sm font-medium truncate">
                  <%= render_slot(@title) %>
                </span>
                <span class="text-gray-400 text-sm truncate"><%= render_slot(@subtitle) %></span>
              </span>
            </span>
            <svg
              class="flex-shrink-0 h-5 w-5 text-gray-500 group-hover:text-gray-400"
              xmlns="http://www.w3.org/2000/svg"
              viewBox="0 0 20 20"
              fill="currentColor"
              aria-hidden="true"
            >
              <path
                fill-rule="evenodd"
                d="M10 3a1 1 0 01.707.293l3 3a1 1 0 01-1.414 1.414L10 5.414 7.707 7.707a1 1 0 01-1.414-1.414l3-3A1 1 0 0110 3zm-3.707 9.293a1 1 0 011.414 0L10 14.586l2.293-2.293a1 1 0 011.414 1.414l-3 3a1 1 0 01-1.414 0l-3-3a1 1 0 010-1.414z"
                clip-rule="evenodd"
              >
              </path>
            </svg>
          </span>
        </button>
      </div>
      <div
        id={"#{@id}-dropdown"}
        phx-click-away={hide_dropdown("##{@id}-dropdown")}
        class="hidden z-10 mx-3 origin-top absolute right-0 left-0 mt-1 rounded-md shadow-lg bg-gray-900 ring-1 ring-gray-900 ring-opacity-5 divide-y divide-gray-700"
        role="menu"
        aria-labelledby={@id}
      >
        <div class="py-1" role="none">
          <%= for link <- @link do %>
            <.link
              tabindex="-1"
              role="menuitem"
              class="block px-4 py-2 text-sm text-gray-200 hover:bg-gray-800 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-offset-gray-800 focus:ring-purple-400"
              {link}
            >
              <%= render_slot(link) %>
            </.link>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  def show_mobile_sidebar(js \\ %JS{}) do
    js
    |> JS.show(to: "#mobile-sidebar-container", transition: "fade-in")
    |> JS.show(
      to: "#mobile-sidebar",
      display: "flex",
      time: 300,
      transition:
        {"transition ease-in-out duration-300 transform", "-translate-x-full", "translate-x-0"}
    )
    |> JS.hide(to: "#show-mobile-sidebar", transition: "fade-out")
    |> JS.dispatch("js:exec", to: "#hide-mobile-sidebar", detail: %{call: "focus", args: []})
  end

  def hide_mobile_sidebar(js \\ %JS{}) do
    js
    |> JS.hide(to: "#mobile-sidebar-container", transition: "fade-out")
    |> JS.hide(
      to: "#mobile-sidebar",
      time: 300,
      transition:
        {"transition ease-in-out duration-300 transform", "translate-x-0", "-translate-x-full"}
    )
    |> JS.show(to: "#show-mobile-sidebar", transition: "fade-in")
    |> JS.dispatch("js:exec", to: "#show-mobile-sidebar", detail: %{call: "focus", args: []})
  end

  def show(js \\ %JS{}, selector) do
    JS.show(js,
      to: selector,
      time: 300,
      display: "inline-block",
      transition:
        {"ease-out duration-300", "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"}
    )
  end

  def hide(js \\ %JS{}, selector) do
    JS.hide(js,
      to: selector,
      time: 300,
      transition:
        {"transition ease-in duration-300", "transform opacity-100 scale-100",
         "transform opacity-0 scale-95"}
    )
  end

  def show_dropdown(to) do
    JS.show(
      to: to,
      transition:
        {"transition ease-out duration-120", "transform opacity-0 scale-95",
         "transform opacity-100 scale-100"}
    )
    |> JS.set_attribute({"aria-expanded", "true"}, to: to)
  end

  def hide_dropdown(to) do
    JS.hide(
      to: to,
      transition:
        {"transition ease-in duration-120", "transform opacity-100 scale-100",
         "transform opacity-0 scale-95"}
    )
    |> JS.remove_attribute("aria-expanded", to: to)
  end

  def show_modal(js \\ %JS{}, id) when is_binary(id) do
    js
    |> JS.show(
      to: "##{id}",
      display: "inline-block",
      transition: {"ease-out duration-300", "opacity-0", "opacity-100"}
    )
    |> JS.show(
      to: "##{id}-container",
      display: "inline-block",
      transition:
        {"ease-out duration-300", "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"}
    )
    |> js_exec("##{id}-confirm", "focus", [])
  end

  def hide_modal(js \\ %JS{}, id) do
    js
    |> JS.remove_class("fade-in", to: "##{id}")
    |> JS.hide(
      to: "##{id}",
      transition: {"ease-in duration-200", "opacity-100", "opacity-0"}
    )
    |> JS.hide(
      to: "##{id}-container",
      transition:
        {"ease-in duration-200", "opacity-100 translate-y-0 sm:scale-100",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}
    )
    |> JS.dispatch("click", to: "##{id} [data-modal-return]")
  end

  attr :id, :string, required: true
  attr :show, :boolean, default: false
  attr :patch, :string, default: nil
  attr :navigate, :string, default: nil
  attr :on_cancel, JS, default: %JS{}
  attr :on_confirm, JS, default: %JS{}
  attr :rest, :global

  slot :title
  slot :confirm
  slot :cancel

  def modal(assigns) do
    ~H"""
    <div
      id={@id}
      class={"fixed z-10 inset-0 overflow-y-auto #{if @show, do: "fade-in", else: "hidden"}"}
      {@rest}
    >
      <.focus_wrap id={"#{@id}-focus-wrap"}>
        <div
          class="flex items-end justify-center min-h-screen pt-4 px-4 pb-20 text-center sm:block sm:p-0"
          aria-labelledby={"#{@id}-title"}
          aria-describedby={"#{@id}-description"}
          role="dialog"
          aria-modal="true"
          tabindex="0"
        >
          <div class="fixed inset-0 bg-gray-700 bg-opacity-75 transition-opacity" aria-hidden="true">
          </div>
          <span class="hidden sm:inline-block sm:align-middle sm:h-screen" aria-hidden="true">
            &#8203;
          </span>
          <div
            id={"#{@id}-container"}
            class={
              "#{if @show, do: "fade-in-scale", else: "hidden"} sticky inline-block align-bottom bg-gray-900 rounded-lg px-4 pt-5 pb-4 text-left overflow-hidden shadow-xl transform sm:my-8 sm:align-middle sm:max-w-xl sm:w-full sm:p-6"
            }
            phx-window-keydown={hide_modal(@on_cancel, @id)}
            phx-key="escape"
            phx-click-away={hide_modal(@on_cancel, @id)}
          >
            <%= if @patch do %>
              <.link patch={@patch} data-modal-return class="hidden"></.link>
            <% end %>
            <%= if @navigate do %>
              <.link navigate={@navigate} data-modal-return class="hidden"></.link>
            <% end %>
            <div class="sm:flex sm:items-start">
              <div class="mx-auto flex-shrink-0 flex items-center justify-center h-8 w-8 rounded-full bg-purple-800 sm:mx-0">
                <Heroicons.information_circle class="h-6 w-6 text-purple-300" />
              </div>
              <div class="mt-3 text-center sm:mt-0 sm:ml-4 sm:text-left w-full mr-12">
                <h3 class="text-lg leading-6 font-medium text-gray-50" id={"#{@id}-title"}>
                  <%= render_slot(@title) %>
                </h3>
                <div class="mt-2">
                  <p id={"#{@id}-content"} class="text-sm text-gray-400">
                    <%= render_slot(@inner_block) %>
                  </p>
                </div>
              </div>
            </div>
            <div class="mt-5 sm:mt-4 sm:flex sm:flex-row-reverse">
              <%= for confirm <- @confirm do %>
                <button
                  id={"#{@id}-confirm"}
                  class="w-full inline-flex justify-center rounded-md border border-transparent shadow-sm px-4 py-2 bg-purple-600 text-base font-medium text-white hover:bg-purple-500 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-purple-400 sm:ml-3 sm:w-auto sm:text-sm"
                  phx-click={@on_confirm}
                  phx-disable-with
                  {assigns_to_attributes(confirm)}
                >
                  <%= render_slot(confirm) %>
                </button>
              <% end %>
              <%= for cancel <- @cancel do %>
                <button
                  class="mt-3 w-full inline-flex justify-center rounded-md border border-gray-600 shadow-sm px-4 py-2 bg-gray-900 text-base font-medium text-gray-200 hover:bg-gray-900 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-purple-400 sm:mt-0 sm:w-auto sm:text-sm"
                  phx-click={hide_modal(@on_cancel, @id)}
                  {assigns_to_attributes(cancel)}
                >
                  <%= render_slot(cancel) %>
                </button>
              <% end %>
            </div>
          </div>
        </div>
      </.focus_wrap>
    </div>
    """
  end

  slot :actions

  def title_bar(assigns) do
    ~H"""
    <!-- Page title & actions -->
    <div class="border-b border-gray-700 px-4 py-4 flex items-center justify-between sm:px-6 lg:px-8 sm:h-24">
      <div class="flex-1 min-w-0">
        <h1 class="text-lg font-medium leading-6 text-gray-50 focus:outline-none">
          <%= render_slot(@inner_block) %>
        </h1>
      </div>
      <%= if Enum.count(@actions) > 0 do %>
        <div class="flex sm:ml-4 space-x-4">
          <%= render_slot(@actions) %>
        </div>
      <% end %>
    </div>
    """
  end

  attr :patch, :string
  attr :primary, :boolean, default: false
  attr :rest, :global

  slot :inner_block

  def button(%{patch: _} = assigns) do
    ~H"""
    <%= if @primary do %>
      <%= live_patch [to: @patch, class: "order-0 inline-flex items-center px-4 py-2 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-purple-600 hover:bg-purple-500 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-purple-400 sm:order-1 sm:ml-3"] ++
        Map.to_list(@rest) do %>
        <%= render_slot(@inner_block) %>
      <% end %>
    <% else %>
      <%= live_patch [to: @patch, class: "order-1 inline-flex items-center px-4 py-2 border border-gray-600 shadow-sm text-sm font-medium rounded-md text-gray-200 bg-gray-900 hover:bg-gray-900 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-purple-400 sm:order-0 sm:ml-0 lg:ml-3"] ++
        assigns_to_attributes(assigns, [:primary, :patch]) do %>
        <%= render_slot(@inner_block) %>
      <% end %>
    <% end %>
    """
  end

  def button(%{} = assigns) do
    ~H"""
    <%= if @primary do %>
      <button
        type="button"
        class="order-0 inline-flex items-center px-4 py-2 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-purple-600 hover:bg-purple-500 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-purple-400 sm:order-1 sm:ml-3"
        {@rest}
      >
        <%= render_slot(@inner_block) %>
      </button>
    <% else %>
      <button
        type="button"
        class="order-1 inline-flex items-center px-4 py-2 border border-gray-600 shadow-sm text-sm font-medium rounded-md text-gray-200 bg-gray-900 hover:bg-gray-900 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-purple-400 sm:order-0 sm:ml-0 lg:ml-3"
        {@rest}
      >
        <%= render_slot(@inner_block) %>
      </button>
    <% end %>
    """
  end

  attr :id, :string, required: true
  attr :video, :any, required: true

  def video_entry(assigns) do
    ~H"""
    <div
      id={@id}
      class="cursor-pointer truncate"
      phx-click={
        JS.push("join", value: %{video_id: @video.id}, target: "#chat-box")
        |> JS.dispatch("js:play_video",
          to: "#video-player",
          detail: %{player: %{src: @video.url, type: Library.player_type(@video)}}
        )
      }
    >
      <div class="relative flex items-center justify-center overflow-hidden rounded-2xl aspect-[16/9] bg-gray-800">
        <Heroicons.play :if={!@video.thumbnails_ready} solid class="h-12 w-12 text-gray-500" />
        <img
          :if={@video.thumbnails_ready}
          src={Library.thumbnail_url(@video)}
          alt={@video.title}
          class="absolute w-full h-full object-cover transition-transform duration-200 scale-105 hover:scale-110 z-10"
        />

        <div
          :if={@video.is_live}
          class="absolute font-medium text-xs px-2 py-0.5 rounded-xl bottom-1 bg-gray-950/90 text-white right-1 z-20"
        >
          🔴 LIVE
        </div>
        <div
          :if={not @video.is_live and @video.duration != 0}
          class="absolute font-medium text-xs px-2 py-0.5 rounded-xl bottom-1 bg-gray-950/90 text-white right-1 z-20"
        >
          <%= Library.to_hhmmss(@video.duration) %>
        </div>
      </div>
      <div class="pt-2 text-base font-semibold truncate"><%= @video.title %></div>
      <div class="text-gray-300 text-sm font-medium"><%= @video.channel_name %></div>
      <div class="text-gray-300 text-sm"><%= Timex.from_now(@video.inserted_at) %></div>
    </div>
    """
  end

  attr :id, :string, required: true
  attr :videos, :list, required: true

  slot :inner_block

  def playlist(assigns) do
    ~H"""
    <div class="mt-8 sm:block">
      <div class="align-middle inline-block min-w-full">
        <div id={@id} class="px-4 sm:px-6 lg:px-8 min-w-full">
          <h2 class="text-gray-400 text-xs font-medium uppercase tracking-wide">
            Library
          </h2>
          <div
            id={"#{@id}-body"}
            class="mt-3 gap-8 grid sm:grid-cols-2 lg:grid-cols-1 xl:grid-cols-2 2xl:grid-cols-3"
            phx-update="stream"
          >
            <.video_entry :for={{id, video} <- @videos} id={id} video={video} />
          </div>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Calls a wired up event listener to call a function with arguments.

      window.addEventListener("js:exec", e => e.target[e.detail.call](...e.detail.args))
  """
  def js_exec(js \\ %JS{}, to, call, args) do
    JS.dispatch(js, "js:exec", to: to, detail: %{call: call, args: args})
  end

  def focus(js \\ %JS{}, parent, to) do
    JS.dispatch(js, "js:focus", to: to, detail: %{parent: parent})
  end

  def focus_closest(js \\ %JS{}, to) do
    js
    |> JS.dispatch("js:focus-closest", to: to)
    |> hide(to)
  end

  @doc """
  Generates tag for inlined form input errors.
  """
  def error_tag(form, field) do
    error(%{
      errors: form.errors,
      field: field,
      input_name: Phoenix.HTML.Form.input_name(form, field)
    })
  end

  def error(%{errors: errors, field: field} = assigns) do
    assigns =
      assigns
      |> assign(:error_values, Keyword.get_values(errors, field))
      |> assign_new(:class, fn -> "" end)

    ~H"""
    <%= for error <- @error_values do %>
      <span
        phx-feedback-for={@input_name}
        class={
          "invalid-feedback inline-block text-sm text-red-400 #{@class}"
        }
      >
        <%= translate_error(error) %>
      </span>
    <% end %>
    """
  end

  @doc """
  Translates an error message using gettext.
  """
  def translate_error({msg, opts}) do
    # When using gettext, we typically pass the strings we want
    # to translate as a static argument:
    #
    #     # Translate "is invalid" in the "errors" domain
    #     dgettext("errors", "is invalid")
    #
    #     # Translate the number of files with plural rules
    #     dngettext("errors", "1 file", "%{count} files", count)
    #
    # Because the error messages we show in our forms and APIs
    # are defined inside Ecto, we need to translate them dynamically.
    # This requires us to call the Gettext module passing our gettext
    # backend as first argument.
    #
    # Note we use the "errors" domain, which means translations
    # should be written to the errors.po file. The :count option is
    # set by Ecto and indicates we should also apply plural rules.
    if count = opts[:count] do
      Gettext.dngettext(AlgoraWeb.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(AlgoraWeb.Gettext, "errors", msg, opts)
    end
  end

  def translate_changeset_errors(changeset) do
    changeset.errors
    |> Enum.map_join("\n", fn {key, value} -> "#{key} #{translate_error(value)}" end)
  end
end
