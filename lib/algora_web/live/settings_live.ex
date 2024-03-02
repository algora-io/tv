defmodule AlgoraWeb.SettingsLive do
  use AlgoraWeb, :live_view

  alias Algora.Accounts

  def render(assigns) do
    ~H"""
    <.header>
      Settings
      <:subtitle>
        Update your account details
      </:subtitle>
    </.header>

    <div class="max-w-3xl px-4 sm:px-6 lg:px-8 mt-4">
      <.simple_form for={@form} phx-change="validate" phx-submit="save">
        <.input field={@form[:handle]} label="Handle" />
        <.input field={@form[:name]} label="Name" />
        <.input label="Email" name="email" value={@current_user.email} disabled />
        <.input field={@form[:channel_tagline]} label="Stream tagline" />
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

    {:ok,
     socket
     |> assign(current_user: current_user)
     |> assign_form(changeset)}
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
