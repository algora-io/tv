defmodule AlgoraWeb.CoreComponents do
  @moduledoc """
  Provides core UI components.

  The components in this module use Tailwind CSS, a utility-first CSS framework.
  See the [Tailwind CSS documentation](https://tailwindcss.com) to learn how to
  customize the generated components in this module.

  Icons are provided by [heroicons](https://heroicons.com). See `icon/1` for usage.
  """
  use Phoenix.Component
  use AlgoraWeb, :verified_routes

  alias Algora.{Accounts, Library}
  alias Phoenix.LiveView.JS
  import AlgoraWeb.Gettext

  slot :inner_block

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

  @doc """
  Renders a modal.

  ## Examples

      <.modal id="confirm-modal">
        Are you sure?
        <:confirm>OK</:confirm>
        <:cancel>Cancel</:cancel>
      </.modal>

  JS commands may be passed to the `:on_cancel` and `on_confirm` attributes
  for the caller to react to each button press, for example:

      <.modal id="confirm" on_confirm={JS.push("delete")} on_cancel={JS.navigate(~p"/posts")}>
        Are you sure you?
        <:confirm>OK</:confirm>
        <:cancel>Cancel</:cancel>
      </.modal>
  """
  attr :id, :string, required: true
  attr :show, :boolean, default: false
  attr :on_cancel, JS, default: %JS{}
  attr :on_confirm, JS, default: %JS{}

  slot :inner_block, required: true
  slot :title
  slot :subtitle
  slot :confirm
  slot :cancel

  def modal(assigns) do
    ~H"""
    <div
      id={@id}
      phx-mounted={@show && show_modal(@id)}
      phx-remove={hide_modal(@id)}
      class="relative z-50 hidden"
    >
      <div
        id={"#{@id}-bg"}
        class="fixed inset-0 bg-gray-900/90 transition-opacity"
        aria-hidden="true"
      />
      <div
        class="fixed inset-0 overflow-y-auto"
        aria-labelledby={"#{@id}-title"}
        aria-describedby={"#{@id}-description"}
        role="dialog"
        aria-modal="true"
        tabindex="0"
      >
        <div class="flex min-h-full items-center justify-center">
          <div class="w-full max-w-3xl p-4 sm:p-6 lg:py-8">
            <.focus_wrap
              id={"#{@id}-container"}
              phx-mounted={@show && show_modal(@id)}
              phx-window-keydown={hide_modal(@on_cancel, @id)}
              phx-key="escape"
              phx-click-away={hide_modal(@on_cancel, @id)}
              class="hidden relative rounded-2xl bg-white p-14 shadow-lg shadow-gray-200/10 ring-1 ring-gray-200/10 transition"
            >
              <div class="absolute top-6 right-5">
                <button
                  phx-click={hide_modal(@on_cancel, @id)}
                  type="button"
                  class="-m-3 flex-none p-3 opacity-20 hover:opacity-40"
                  aria-label={gettext("close")}
                >
                  <.icon name="hero-x-mark-solid" class="w-5 h-5" />
                </button>
              </div>
              <div id={"#{@id}-content"}>
                <header :if={@title != []}>
                  <h1 id={"#{@id}-title"} class="text-lg font-semibold leading-8 text-gray-100">
                    <%= render_slot(@title) %>
                  </h1>
                  <p
                    :if={@subtitle != []}
                    id={"#{@id}-description"}
                    class="mt-2 text-sm leading-6 text-gray-300"
                  >
                    <%= render_slot(@subtitle) %>
                  </p>
                </header>
                <%= render_slot(@inner_block) %>
                <div :if={@confirm != [] or @cancel != []} class="ml-6 mb-4 flex items-center gap-5">
                  <.button
                    :for={confirm <- @confirm}
                    id={"#{@id}-confirm"}
                    phx-click={@on_confirm}
                    phx-disable-with
                    class="py-2 px-3"
                  >
                    <%= render_slot(confirm) %>
                  </.button>
                  <.link
                    :for={cancel <- @cancel}
                    phx-click={hide_modal(@on_cancel, @id)}
                    class="text-sm font-semibold leading-6 text-gray-50 hover:text-gray-200"
                  >
                    <%= render_slot(cancel) %>
                  </.link>
                </div>
              </div>
            </.focus_wrap>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Renders flash notices.

  ## Examples

      <.flash kind={:info} flash={@flash} />
      <.flash kind={:info} phx-mounted={show("#flash")}>Welcome Back!</.flash>
  """
  attr :id, :string, default: "flash", doc: "the optional id of flash container"
  attr :flash, :map, default: %{}, doc: "the map of flash messages to display"
  attr :title, :string, default: nil
  attr :kind, :atom, values: [:info, :error], doc: "used for styling and flash lookup"
  attr :autoshow, :boolean, default: true, doc: "whether to auto show the flash on mount"
  attr :close, :boolean, default: true, doc: "whether the flash can be closed"
  attr :rest, :global, doc: "the arbitrary HTML attributes to add to the flash container"

  slot :inner_block, doc: "the optional inner block that renders the flash message"

  def flash(assigns) do
    ~H"""
    <div
      :if={msg = render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind)}
      id={@id}
      phx-mounted={@autoshow && show("##{@id}")}
      phx-click={JS.push("lv:clear-flash", value: %{key: @kind}) |> hide("##{@id}")}
      role="alert"
      class={[
        "fixed hidden top-2 right-2 w-80 sm:w-96 z-50 rounded-lg p-3 shadow-md shadow-gray-50/5 ring-1",
        @kind == :info && "bg-green-900 text-green-100 ring-green-9000 fill-cyan-900",
        @kind == :error && "bg-red-900 p-3 text-red-50 shadow-md ring-red-9000 fill-red-50"
      ]}
      {@rest}
    >
      <p :if={@title} class="flex items-center gap-1.5 text-[0.8125rem] font-semibold leading-6">
        <.icon :if={@kind == :info} name="hero-information-circle-mini" class="w-4 h-4" />
        <.icon :if={@kind == :error} name="hero-exclamation-circle-mini" class="w-4 h-4" />
        <%= @title %>
      </p>
      <p class="mt-2 text-[0.8125rem] leading-5"><%= msg %></p>
      <button
        :if={@close}
        type="button"
        class="group absolute top-2 right-1 p-2"
        aria-label={gettext("close")}
      >
        <.icon name="hero-x-mark-solid" class="w-5 h-5 opacity-40 group-hover:opacity-70" />
      </button>
    </div>
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"

  def flash_group(assigns) do
    ~H"""
    <.flash kind={:info} title="Success!" flash={@flash} />
    <.flash kind={:error} title="Error!" flash={@flash} />
    <.flash
      id="disconnected"
      kind={:error}
      title="We can't find the internet"
      close={false}
      autoshow={false}
      phx-disconnected={show("#disconnected")}
      phx-connected={hide("#disconnected")}
    >
      Attempting to reconnect <.icon name="hero-arrow-path" class="ml-1 w-3 h-3 animate-spin" />
    </.flash>
    """
  end

  @doc """
  Renders a simple form.

  ## Examples

      <.simple_form for={@form} phx-change="validate" phx-submit="save">
        <.input field={@form[:email]} label="Email"/>
        <.input field={@form[:username]} label="Username" />
        <:actions>
          <.button>Save</.button>
        </:actions>
      </.simple_form>
  """
  attr :for, :any, required: true, doc: "the datastructure for the form"
  attr :as, :any, default: nil, doc: "the server side parameter to collect all input under"

  attr :rest, :global,
    include: ~w(autocomplete name rel action enctype method novalidate target),
    doc: "the arbitrary HTML attributes to apply to the form tag"

  slot :inner_block, required: true
  slot :actions, doc: "the slot for form actions, such as a submit button"

  def simple_form(assigns) do
    ~H"""
    <.form :let={f} for={@for} as={@as} {@rest}>
      <div class="space-y-8 bg-white mt-10">
        <%= render_slot(@inner_block, f) %>
        <div :for={action <- @actions} class="mt-2 flex items-center justify-between gap-6">
          <%= render_slot(action, f) %>
        </div>
      </div>
    </.form>
    """
  end

  @doc """
  Renders a button.

  ## Examples

      <.button>Send!</.button>
      <.button phx-click="go" class="ml-2">Send!</.button>
  """
  attr :type, :string, default: nil
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(disabled form name value)

  slot :inner_block, required: true

  def button(assigns) do
    ~H"""
    <button
      type={@type}
      class={[
        "phx-submit-loading:opacity-75 rounded-lg bg-gray-50 hover:bg-gray-200 py-2 px-3",
        "text-sm font-semibold leading-6 text-white active:text-white/80",
        @class
      ]}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </button>
    """
  end

  @doc """
  Renders an input with label and error messages.

  A `%Phoenix.HTML.Form{}` and field name may be passed to the input
  to build input names and error messages, or all the attributes and
  errors may be passed explicitly.

  ## Examples

      <.input field={@form[:email]} type="email" />
      <.input name="my-input" errors={["oh no!"]} />
  """
  attr :id, :any, default: nil
  attr :name, :any
  attr :label, :string, default: nil
  attr :value, :any

  attr :type, :string,
    default: "text",
    values: ~w(checkbox color date datetime-local email file hidden month number password
               range radio search select tel text textarea time url week)

  attr :field, Phoenix.HTML.FormField,
    doc: "a form field struct retrieved from the form, for example: @form[:email]"

  attr :errors, :list, default: []
  attr :checked, :boolean, doc: "the checked flag for checkbox inputs"
  attr :prompt, :string, default: nil, doc: "the prompt for select inputs"
  attr :options, :list, doc: "the options to pass to Phoenix.HTML.Form.options_for_select/2"
  attr :multiple, :boolean, default: false, doc: "the multiple flag for select inputs"
  attr :rest, :global, include: ~w(autocomplete cols disabled form max maxlength min minlength
                                   pattern placeholder readonly required rows size step)
  slot :inner_block

  def input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(field.errors, &translate_error(&1)))
    |> assign_new(:name, fn -> if assigns.multiple, do: field.name <> "[]", else: field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> input()
  end

  def input(%{type: "checkbox", value: value} = assigns) do
    assigns =
      assign_new(assigns, :checked, fn -> Phoenix.HTML.Form.normalize_value("checkbox", value) end)

    ~H"""
    <div phx-feedback-for={@name}>
      <label class="flex items-center gap-4 text-sm leading-6 text-gray-300">
        <input type="hidden" name={@name} value="false" />
        <input
          type="checkbox"
          id={@id || @name}
          name={@name}
          value="true"
          checked={@checked}
          class="rounded border-gray-600 text-gray-50 focus:ring-gray-50"
          {@rest}
        />
        <%= @label %>
      </label>
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  def input(%{type: "select"} = assigns) do
    ~H"""
    <div phx-feedback-for={@name}>
      <.label for={@id}><%= @label %></.label>
      <select
        id={@id}
        name={@name}
        class="mt-1 block w-full py-2 px-3 border border-gray-600 bg-white rounded-md shadow-sm focus:outline-none focus:ring-gray-9000 focus:border-gray-9000 sm:text-sm"
        multiple={@multiple}
        {@rest}
      >
        <option :if={@prompt} value=""><%= @prompt %></option>
        <%= Phoenix.HTML.Form.options_for_select(@options, @value) %>
      </select>
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  def input(%{type: "textarea"} = assigns) do
    ~H"""
    <div phx-feedback-for={@name}>
      <.label for={@id}><%= @label %></.label>
      <textarea
        id={@id || @name}
        name={@name}
        class={[
          "mt-2 block min-h-[6rem] w-full rounded-lg border-gray-600 py-[7px] px-[11px]",
          "text-gray-50 focus:border-gray-500 focus:outline-none focus:ring-4 focus:ring-gray-100/5 sm:text-sm sm:leading-6",
          "phx-no-feedback:border-gray-600 phx-no-feedback:focus:border-gray-500 phx-no-feedback:focus:ring-gray-100/5",
          "border-gray-600 focus:border-gray-500 focus:ring-gray-100/5",
          @errors != [] && "border-red-500 focus:border-red-500 focus:ring-red-500/10"
        ]}
        {@rest}
      ><%= Phoenix.HTML.Form.normalize_value("textarea", @value) %></textarea>
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  def input(assigns) do
    ~H"""
    <div phx-feedback-for={@name}>
      <.label for={@id}><%= @label %></.label>
      <input
        type={@type}
        name={@name}
        id={@id || @name}
        value={Phoenix.HTML.Form.normalize_value(@type, @value)}
        class={[
          "mt-2 block w-full rounded-lg border-gray-600 py-[7px] px-[11px]",
          "text-gray-50 focus:outline-none focus:ring-4 sm:text-sm sm:leading-6",
          "phx-no-feedback:border-gray-600 phx-no-feedback:focus:border-gray-500 phx-no-feedback:focus:ring-gray-100/5",
          "border-gray-600 focus:border-gray-500 focus:ring-gray-100/5",
          @errors != [] && "border-red-500 focus:border-red-500 focus:ring-red-500/10"
        ]}
        {@rest}
      />
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  @doc """
  Renders a label.
  """
  attr :for, :string, default: nil
  slot :inner_block, required: true

  def label(assigns) do
    ~H"""
    <label for={@for} class="block text-sm font-semibold leading-6 text-gray-100">
      <%= render_slot(@inner_block) %>
    </label>
    """
  end

  @doc """
  Generates a generic error message.
  """
  slot :inner_block, required: true

  def error(assigns) do
    ~H"""
    <p class="phx-no-feedback:hidden mt-3 flex gap-3 text-sm leading-6 text-red-300">
      <.icon name="hero-exclamation-circle-mini" class="mt-0.5 w-5 h-5 flex-none" />
      <%= render_slot(@inner_block) %>
    </p>
    """
  end

  @doc """
  Renders a header with title.
  """
  attr :class, :string, default: nil

  slot :inner_block, required: true
  slot :subtitle
  slot :actions

  def header(assigns) do
    ~H"""
    <header class={[@actions != [] && "flex items-center justify-between gap-6", @class]}>
      <div>
        <h1 class="text-lg font-semibold leading-8 text-gray-100">
          <%= render_slot(@inner_block) %>
        </h1>
        <p :if={@subtitle != []} class="mt-2 text-sm leading-6 text-gray-300">
          <%= render_slot(@subtitle) %>
        </p>
      </div>
      <div class="flex-none"><%= render_slot(@actions) %></div>
    </header>
    """
  end

  @doc ~S"""
  Renders a table with generic styling.

  ## Examples

      <.table id="users" rows={@users}>
        <:col :let={user} label="id"><%= user.id %></:col>
        <:col :let={user} label="username"><%= user.username %></:col>
      </.table>
  """
  attr :id, :string, required: true
  attr :rows, :list, required: true
  attr :row_id, :any, default: nil, doc: "the function for generating the row id"
  attr :row_click, :any, default: nil, doc: "the function for handling phx-click on each row"

  attr :row_item, :any,
    default: &Function.identity/1,
    doc: "the function for mapping each row before calling the :col and :action slots"

  slot :col, required: true do
    attr :label, :string
  end

  slot :action, doc: "the slot for showing user actions in the last table column"

  def table(assigns) do
    assigns =
      with %{rows: %Phoenix.LiveView.LiveStream{}} <- assigns do
        assign(assigns, row_id: assigns.row_id || fn {id, _item} -> id end)
      end

    ~H"""
    <div class="overflow-y-auto px-4 sm:overflow-visible sm:px-0">
      <table class="mt-11 w-[40rem] sm:w-full">
        <thead class="text-left text-[0.8125rem] leading-6 text-gray-9000">
          <tr>
            <th :for={col <- @col} class="p-0 pb-4 pr-6 font-normal"><%= col[:label] %></th>
            <th class="relative p-0 pb-4"><span class="sr-only"><%= gettext("Actions") %></span></th>
          </tr>
        </thead>
        <tbody
          id={@id}
          phx-update={match?(%Phoenix.LiveView.LiveStream{}, @rows) && "stream"}
          class="relative divide-y divide-gray-800 border-t border-gray-700 text-sm leading-6 text-gray-200"
        >
          <tr :for={row <- @rows} id={@row_id && @row_id.(row)} class="group hover:bg-gray-900">
            <td
              :for={{col, i} <- Enum.with_index(@col)}
              phx-click={@row_click && @row_click.(row)}
              class={["relative p-0", @row_click && "hover:cursor-pointer"]}
            >
              <div class="block py-4 pr-6">
                <span class="absolute -inset-y-px right-0 -left-4 group-hover:bg-gray-900 sm:rounded-l-xl" />
                <span class={["relative", i == 0 && "font-semibold text-gray-50"]}>
                  <%= render_slot(col, @row_item.(row)) %>
                </span>
              </div>
            </td>
            <td :if={@action != []} class="relative p-0 w-14">
              <div class="relative whitespace-nowrap py-4 text-right text-sm font-medium">
                <span class="absolute -inset-y-px -right-4 left-0 group-hover:bg-gray-900 sm:rounded-r-xl" />
                <span
                  :for={action <- @action}
                  class="relative ml-4 font-semibold leading-6 text-gray-50 hover:text-gray-200"
                >
                  <%= render_slot(action, @row_item.(row)) %>
                </span>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end

  @doc """
  Renders a data list.

  ## Examples

      <.list>
        <:item title="Title"><%= @post.title %></:item>
        <:item title="Views"><%= @post.views %></:item>
      </.list>
  """
  slot :item, required: true do
    attr :title, :string, required: true
  end

  def list(assigns) do
    ~H"""
    <div class="mt-14">
      <dl class="-my-4 divide-y divide-gray-800">
        <div :for={item <- @item} class="flex gap-4 py-4 sm:gap-8">
          <dt class="w-1/4 flex-none text-[0.8125rem] leading-6 text-gray-9000"><%= item.title %></dt>
          <dd class="text-sm leading-6 text-gray-200"><%= render_slot(item) %></dd>
        </div>
      </dl>
    </div>
    """
  end

  @doc """
  Renders a back navigation link.

  ## Examples

      <.back navigate={~p"/posts"}>Back to posts</.back>
  """
  attr :navigate, :any, required: true
  slot :inner_block, required: true

  def back(assigns) do
    ~H"""
    <div class="mt-16">
      <.link
        navigate={@navigate}
        class="text-sm font-semibold leading-6 text-gray-50 hover:text-gray-200"
      >
        <.icon name="hero-arrow-left-solid" class="w-3 h-3" />
        <%= render_slot(@inner_block) %>
      </.link>
    </div>
    """
  end

  @doc """
  Renders a [Hero Icon](https://heroicons.com).

  Hero icons come in three styles – outline, solid, and mini.
  By default, the outline style is used, but solid an mini may
  be applied by using the `-solid` and `-mini` suffix.

  You can customize the size and colors of the icons by setting
  width, height, and background color classes.

  Icons are extracted from your `priv/hero_icons` directory and bundled
  within your compiled app.css by the plugin in your `assets/tailwind.config.js`.

  ## Examples

      <.icon name="hero-cake" />
      <.icon name="hero-cake-solid" />
      <.icon name="hero-cake-mini" />
      <.icon name="hero-bolt" class="bg-blue-500 w-10 h-10" />
  """
  attr :name, :string, required: true
  attr :class, :string, default: nil

  def icon(%{name: "hero-" <> _} = assigns) do
    ~H"""
    <span class={[@name, @class]} />
    """
  end

  ## JS Commands

  def show(js \\ %JS{}, selector) do
    JS.show(js,
      to: selector,
      transition:
        {"transition-all transform ease-out duration-300",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"}
    )
  end

  def hide(js \\ %JS{}, selector) do
    JS.hide(js,
      to: selector,
      time: 200,
      transition:
        {"transition-all transform ease-in duration-200",
         "opacity-100 translate-y-0 sm:scale-100",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}
    )
  end

  def show_modal(js \\ %JS{}, id) when is_binary(id) do
    js
    |> JS.show(to: "##{id}")
    |> JS.show(
      to: "##{id}-bg",
      transition: {"transition-all transform ease-out duration-300", "opacity-0", "opacity-100"}
    )
    |> show("##{id}-container")
    |> JS.add_class("overflow-hidden", to: "body")
    |> JS.focus_first(to: "##{id}-content")
  end

  def hide_modal(js \\ %JS{}, id) do
    js
    |> JS.hide(
      to: "##{id}-bg",
      transition: {"transition-all transform ease-in duration-200", "opacity-100", "opacity-0"}
    )
    |> hide("##{id}-container")
    |> JS.hide(to: "##{id}", transition: {"block", "block", "hidden"})
    |> JS.remove_class("overflow-hidden", to: "body")
    |> JS.pop_focus()
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

  @doc """
  Translates the errors for a field from a keyword list of errors.
  """
  def translate_errors(errors, field) when is_list(errors) do
    for {^field, {msg, opts}} <- errors, do: translate_error({msg, opts})
  end
end
