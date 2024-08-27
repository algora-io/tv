defmodule AlgoraWeb.SettingsLive do
  use AlgoraWeb, :live_view

  alias Algora.Accounts
  alias Algora.Accounts.Destination
  alias AlgoraWeb.RTMPDestinationIconComponent

  def render(assigns) do
    ~H"""
    <div class="max-w-3xl mx-auto pt-2 pb-6 px-4 sm:px-6 space-y-6">
      <div class="space-y-6 bg-white/5 rounded-lg p-6 ring-1 ring-white/15">
        <.header>
          Settings
          <:subtitle>
            Update your account details
          </:subtitle>
        </.header>

        <.simple_form for={@form} phx-change="validate" phx-submit="save">
          <.input field={@form[:handle]} label="Handle" />
          <.input field={@form[:name]} label="Name" />
          <.input label="Email" name="email" value={@current_user.email} disabled />
          <.input field={@form[:channel_tagline]} label="Stream tagline" />
          <div class="space-y-4">
            <div>
              <label for="rtmp_url" class="block text-sm font-medium text-gray-200">
                RTMP URL
              </label>
              <div class="mt-1">
                <div class="py-2 px-3 bg-gray-800 text-white rounded-md text-sm">
                  <%= "rtmp://#{URI.parse(AlgoraWeb.Endpoint.url()).host}:#{Algora.config([:rtmp_port])}/live" %>
                </div>
              </div>
              <p class="mt-2 text-sm text-gray-400">
                Paste into OBS Studio > File > Settings > Stream > Server
              </p>
            </div>

            <div>
              <label for="stream_key" class="block text-sm font-medium text-gray-200">
                Stream key
              </label>
              <div class="mt-1 flex items-center">
                <input
                  type="password"
                  value={@current_user.stream_key}
                  readonly
                  class="bg-gray-800 text-white flex-1 rounded-md py-2 px-3 text-sm"
                />
                <button
                  type="button"
                  phx-click="reset_stream_key"
                  class="ml-2 px-3 py-2 bg-gray-700 text-white rounded-md text-sm"
                >
                  Reset
                </button>
                <button
                  type="button"
                  phx-click="copy_stream_key"
                  class="ml-2 px-3 py-2 bg-gray-700 text-white rounded-md text-sm"
                >
                  Copy
                </button>
              </div>
              <p class="mt-2 text-sm text-gray-400">
                Paste into OBS Studio > File > Settings > Stream > Stream Key
              </p>
            </div>
          </div>
          <:actions>
            <.button>Save</.button>
          </:actions>
        </.simple_form>
      </div>
      <div class="space-y-6 bg-white/5 rounded-lg p-6 ring-1 ring-white/15">
        <.header>
          Integrations
          <:subtitle>
            Manage your connected accounts and services
          </:subtitle>
        </.header>
        <div class="space-y-6">
          <.button :if={!@connected_with_restream}>
            <.link href={"/oauth/login/restream?#{URI.encode_query(return_to: "/channel/settings")}"}>
              Connect with Restream
            </.link>
          </.button>
          <.button :if={@connected_with_restream} class="bg-green-600 hover:bg-green-500 text-white">
            <.link
              href={"/oauth/login/restream?#{URI.encode_query(return_to: "/channel/settings")}"}
              class="flex items-center"
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
                class="h-5 w-5 -ml-0.5"
              >
                <path stroke="none" d="M0 0h24v24H0z" fill="none" /><path d="M5 12l5 5l10 -10" />
              </svg>
              <span class="ml-1">Connected with Restream</span>
            </.link>
          </.button>
        </div>
      </div>
      <div class="space-y-6 bg-white/5 rounded-lg p-6 ring-1 ring-white/15">
        <.header>
          Multistreaming
          <:subtitle>
            Stream to multiple destinations
          </:subtitle>
        </.header>
        <div class="space-y-6">
          <ul :if={length(@destinations) > 0} class="space-y-2">
            <%= for destination <- @destinations do %>
              <li class="w-full gap-4 py-2 px-3 border border-gray-600 bg-gray-950 rounded-md shadow-sm focus:outline-none focus:ring-gray-900 focus:border-gray-900 flex items-center justify-between">
                <div class="flex items-center gap-2 truncate">
                  <RTMPDestinationIconComponent.render
                    class="w-6 h-6 shrink-0"
                    url={destination.rtmp_url}
                  />
                  <span class="text-sm truncate"><%= destination.rtmp_url %></span>
                </div>
                <label class="inline-flex items-center cursor-pointer">
                  <span class="hidden sm:inline mr-3 text-sm font-medium text-gray-900 dark:text-gray-300">
                    <%= if destination.active do %>
                      Active
                    <% else %>
                      Inactive
                    <% end %>
                  </span>
                  <input
                    type="checkbox"
                    value=""
                    class="sr-only peer"
                    checked={destination.active}
                    phx-value-id={destination.id}
                    phx-click="toggle_destination"
                  />
                  <div class="relative w-11 h-6 bg-gray-200 rounded-full peer dark:bg-gray-700 peer-focus:ring-4 peer-focus:ring-purple-300 dark:peer-focus:ring-purple-800 peer-checked:after:translate-x-full rtl:peer-checked:after:-translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-0.5 after:start-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all dark:border-gray-600 peer-checked:bg-purple-600">
                  </div>
                </label>
              </li>
            <% end %>
          </ul>
          <.button phx-click="show_add_destination_modal">Add Destination</.button>
        </div>
      </div>
    </div>
    <!-- Add Destination Modal -->
    <.modal :if={@show_add_destination_modal} id="add-destination-modal" show>
      <.header>
        Add Destination
      </.header>
      <.simple_form for={@destination_form} phx-submit="add_destination">
        <.input field={@destination_form[:rtmp_url]} label="RTMP URL" />
        <.input
          field={@destination_form[:stream_key]}
          label="Stream key"
          autocomplete="off"
          type="password"
        />
        <:actions>
          <.button>Add Destination</.button>
        </:actions>
      </.simple_form>
    </.modal>
    """
  end

  def mount(_params, _session, socket) do
    %{current_user: current_user} = socket.assigns

    {:ok, current_user} =
      if current_user.stream_key do
        {:ok, current_user}
      else
        Accounts.gen_stream_key(current_user)
      end

    changeset = Accounts.change_settings(current_user, %{})
    destinations = Accounts.list_destinations(current_user.id)
    destination_changeset = Accounts.change_destination(%Destination{})
    connected_with_restream = Accounts.has_restream_token?(current_user)

    {:ok,
     socket
     |> assign(current_user: current_user)
     |> assign_form(changeset)
     |> assign(destinations: destinations)
     |> assign(destination_form: to_form(destination_changeset))
     |> assign(show_add_destination_modal: false)
     |> assign(connected_with_restream: connected_with_restream)}
  end

  def handle_event("validate", %{"user" => params}, socket) do
    changeset =
      socket.assigns.current_user
      |> Accounts.change_settings(params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"user" => params}, socket) do
    case Accounts.update_settings(socket.assigns.current_user, params) do
      {:ok, user} ->
        {:noreply,
         socket
         |> assign(current_user: user)
         |> put_flash(:info, "Settings updated!")}

      {:error, changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  def handle_event("toggle_destination", %{"id" => id}, socket) do
    destination = Accounts.get_destination!(id)
    Accounts.update_destination(destination, %{active: !destination.active})

    {:noreply,
     assign(socket, :destinations, Accounts.list_destinations(socket.assigns.current_user.id))}
  end

  def handle_event("show_add_destination_modal", _params, socket) do
    {:noreply, assign(socket, show_add_destination_modal: true)}
  end

  def handle_event("add_destination", %{"destination" => destination_params}, socket) do
    case Accounts.create_destination(socket.assigns.current_user, destination_params) do
      {:ok, _destination} ->
        {:noreply,
         socket
         |> assign(:show_add_destination_modal, false)
         |> assign(:destinations, Accounts.list_destinations(socket.assigns.current_user.id))
         |> put_flash(:info, "Destination added successfully!")}

      {:error, changeset} ->
        {:noreply, assign(socket, destination_form: to_form(changeset))}
    end
  end

  def handle_params(params, _url, socket) do
    {:noreply, socket |> apply_action(socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, _params) do
    socket |> assign(:page_title, "Settings")
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  def handle_event("reset_stream_key", _, socket) do
    case Accounts.gen_stream_key(socket.assigns.current_user) do
      {:ok, user} ->
        {:noreply,
         socket
         |> assign(current_user: user)
         |> assign_form(Accounts.change_settings(user, %{}))
         |> put_flash(:info, "Stream key generated successfully")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to generate stream key")}
    end
  end

  def handle_event("copy_stream_key", _, socket) do
    {:noreply,
     socket
     |> push_event("copy_to_clipboard", %{text: socket.assigns.current_user.stream_key})
     |> put_flash(:info, "Stream key copied to clipboard")}
  end

  def handle_event("copy_rtmp_url", _, socket) do
    rtmp_url = "rtmp://#{URI.parse(AlgoraWeb.Endpoint.url()).host}:#{Algora.config([:rtmp_port])}/live"
    {:noreply,
     socket
     |> push_event("copy_to_clipboard", %{text: rtmp_url})
     |> put_flash(:info, "RTMP URL copied to clipboard")}
  end
end
