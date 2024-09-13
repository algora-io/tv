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
          <.live_component
            module={AlgoraWeb.TagsComponent}
            id="channel_tags"
            name="channel_tags"
            tags={@current_user.tags || []}
          />
          <div>
            <.input
              label="Stream URL"
              name="stream_url"
              value={"rtmp://#{URI.parse(AlgoraWeb.Endpoint.url()).host}:#{Algora.config([:rtmp_port])}/#{@current_user.stream_key}"}
              disabled
            />
            <p class="mt-2 text-sm text-gray-400">
              <%= "Paste into OBS Studio > File > Settings > Stream > Server" %>
            </p>
          </div>
          <:actions>
            <.button>Save</.button>
          </:actions>
        </.simple_form>
      </div>
      <div class="space-y-6 bg-white/5 rounded-lg p-6 ring-1 ring-white/15">
        <.header>
          Stream Connection
          <:subtitle>
            Connection details for live streaming with RTMP
          </:subtitle>
        </.header>
        <div class="w-full">
          <div class="flex justify-between items-center">
            <label class="block text-sm font-semibold leading-6 text-gray-100 mb-2">Stream URL</label>
          </div>
          <div class="flex items-center">
            <div class="relative w-full">
              <.input
                class="w-full p-2.5 test-sm mr-16 py-1 px-2 leading-tight block ext-sm"
                name="stream_url"
                value={@stream_url}
                disabled
              />
            </div>
            <button
              id="copy_stream_url"
              class="flex-shrink-0 z-10 inline-flex items-center py-3 px-4 ml-2 text-sm font-medium text-center rounded bg-gray-700 hover:bg-gray-600"
              phx-hook="CopyToClipboard"
              data-value={@stream_url}
              data-notice="Copied Stream Url"
            >
              <span id="default-icon">
                <svg
                  class="w-4 h-4"
                  aria-hidden="true"
                  xmlns="http://www.w3.org/2000/svg"
                  fill="currentColor"
                  viewBox="0 0 18 20"
                >
                  <path d="M16 1h-3.278A1.992 1.992 0 0 0 11 0H7a1.993 1.993 0 0 0-1.722 1H2a2 2 0 0 0-2 2v15a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2V3a2 2 0 0 0-2-2Zm-3 14H5a1 1 0 0 1 0-2h8a1 1 0 0 1 0 2Zm0-4H5a1 1 0 0 1 0-2h8a1 1 0 1 1 0 2Zm0-5H5a1 1 0 0 1 0-2h2V2h4v2h2a1 1 0 1 1 0 2Z" />
                </svg>
              </span>
              <span id="success-icon" class="hidden inline-flex items-center">
                <svg
                  class="w-4 h-4"
                  aria-hidden="true"
                  xmlns="http://www.w3.org/2000/svg"
                  fill="none"
                  viewBox="0 0 16 12"
                >
                  <path
                    stroke="currentColor"
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M1 5.917 5.724 10.5 15 1.5"
                  />
                </svg>
              </span>
            </button>
          </div>
          <p class="mt-2 text-sm text-gray-400">
            <%= "Paste into OBS Studio > File > Settings > Stream > Server" %>
          </p>
        </div>

        <div class="w-full">
          <div class="flex justify-between items-center">
            <label class="block text-sm font-semibold leading-6 text-gray-100 mb-2">Stream Key</label>
          </div>
          <div class="flex items-center">
            <button
              phx-click="regenerate_stream_key"
              class="flex-shrink-0 z-10 inline-flex items-center py-2 px-4 mr-2 text-sm font-medium text-center rounded bg-gray-700 hover:bg-gray-600"
            >
              Generate
            </button>
            <div class="relative w-full">
              <.input
                id="stream_key"
                name="stream_key"
                class="w-full p-2.5 test-sm mr-16 py-1 px-2 leading-tight block ext-sm"
                value={@stream_key}
                disabled
              />
            </div>
            <button
              id="copy_stream_key"
              class="flex-shrink-0 z-10 inline-flex items-center py-3 px-4 ml-2 text-sm font-medium text-center rounded bg-gray-700 hover:bg-gray-600"
              phx-hook="CopyToClipboard"
              data-value={@stream_key}
              data-notice="Copied Stream Key"
            >
              <span id="default-icon">
                <svg
                  class="w-4 h-4"
                  aria-hidden="true"
                  xmlns="http://www.w3.org/2000/svg"
                  fill="currentColor"
                  viewBox="0 0 18 20"
                >
                  <path d="M16 1h-3.278A1.992 1.992 0 0 0 11 0H7a1.993 1.993 0 0 0-1.722 1H2a2 2 0 0 0-2 2v15a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2V3a2 2 0 0 0-2-2Zm-3 14H5a1 1 0 0 1 0-2h8a1 1 0 0 1 0 2Zm0-4H5a1 1 0 0 1 0-2h8a1 1 0 1 1 0 2Zm0-5H5a1 1 0 0 1 0-2h2V2h4v2h2a1 1 0 1 1 0 2Z" />
                </svg>
              </span>
              <span id="success-icon" class="hidden inline-flex items-center">
                <svg
                  class="w-4 h-4"
                  aria-hidden="true"
                  xmlns="http://www.w3.org/2000/svg"
                  fill="none"
                  viewBox="0 0 16 12"
                >
                  <path
                    stroke="currentColor"
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M1 5.917 5.724 10.5 15 1.5"
                  />
                </svg>
              </span>
            </button>
          </div>
          <p class="mt-2 text-sm text-gray-400">
            <%= "Paste into OBS Studio > File > Settings > Stream > Stream Key" %>
          </p>
        </div>
      </div>
      <div class="space-y-6 bg-white/5 rounded-lg p-6 ring-1 ring-white/15">
        <.header>
          Integrations
          <:subtitle>
            Manage your connected accounts and services
          </:subtitle>
        </.header>
        <div class="flex items-center gap-2">
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
          <.button :if={!@connected_with_google}>
            <.link href="/auth/google">
              Connect with YouTube
            </.link>
          </.button>
          <.button :if={@connected_with_google} class="bg-green-600 hover:bg-green-500 text-white">
            <.link href="/auth/google" class="flex items-center">
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
              <span class="ml-1">Connected with YouTube</span>
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
    connected_with_google = Accounts.has_google_token?(current_user)

    rtmp_host =
      case URI.parse(AlgoraWeb.Endpoint.url()).host do
        "localhost" -> "127.0.0.1"
        host -> host
      end

    {:ok,
     socket
     |> assign(current_user: current_user)
     |> assign_form(changeset)
     |> assign(destinations: destinations)
     |> assign(destination_form: to_form(destination_changeset))
     |> assign(show_add_destination_modal: false)
     |> assign(stream_key: current_user.stream_key)
     |> assign(connected_with_restream: connected_with_restream)
     |> assign(connected_with_google: connected_with_google),
     temporary_assigns: [
       stream_url:
         "rtmp://#{rtmp_host}:#{Algora.config([:rtmp_port])}/#{Algora.config([:rtmp_path])}"
     ]}
  end

  def handle_event("validate", %{"user" => params}, socket) do
    changeset =
      socket.assigns.current_user
      |> Accounts.change_settings(params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"user" => params}, socket) do
    current_tags = socket.assigns.current_user.tags
    params_with_tags = Map.put(params, "tags", current_tags)

    case Accounts.update_settings(socket.assigns.current_user, params_with_tags) do
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

  def handle_event("regenerate_stream_key", _params, socket) do
    case Accounts.gen_stream_key(socket.assigns.current_user) do
      {:ok, user} ->
        {:noreply,
         socket
         |> assign(stream_key: user.stream_key)
         |> put_flash(:info, "Stream key regenerated!")}

      {:error, _changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to regenerate stream key!")}
    end
  end

  def handle_event("copied_to_clipboard", %{"notice" => notice}, socket) do
    {:noreply, socket |> put_flash(:info, notice)}
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
end
