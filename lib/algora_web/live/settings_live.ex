defmodule AlgoraWeb.SettingsLive do
  use AlgoraWeb, :live_view

  alias Algora.Accounts

  def render(assigns) do
    ~H"""
    <.title_bar>
      Settings
    </.title_bar>

    <div class="max-w-3xl px-4 sm:px-6 lg:px-8 mt-6">
      <.form
        :let={f}
        id="settings-form"
        for={@changeset}
        phx-change="validate"
        phx-submit="save"
        class="space-y-8 divide-y divide-gray-700"
      >
        <div class="space-y-8 divide-y divide-gray-700">
          <div>
            <div class="mt-6 flex flex-col gap-y-6">
              <div class="sm:col-span-4">
                <label for="handle" class="block text-sm font-medium text-gray-200">
                  Handle
                </label>
                <div class="mt-1 flex rounded-md shadow-sm">
                  <span class="inline-flex items-center px-3 rounded-l-md border border-r-0 border-gray-600 bg-gray-900 text-gray-400 sm:text-sm">
                    <%= URI.parse(AlgoraWeb.Endpoint.url()).host %>/
                  </span>
                  <%= text_input(f, :handle,
                    class:
                      "bg-gray-950 text-white flex-1 focus:ring-purple-400 focus:border-purple-400 block w-full min-w-0 rounded-none rounded-r-md sm:text-sm border-gray-600"
                  ) %>
                </div>
                <.error field={:handle} input_name="user[handle]" errors={f.errors} />
              </div>

              <div class="sm:col-span-4">
                <label for="handle" class="block text-sm font-medium text-gray-200">
                  Email
                </label>
                <div class="mt-1 flex rounded-md shadow-sm">
                  <%= text_input(f, :email,
                    disabled: true,
                    class:
                      "bg-gray-950 text-white flex-1 focus:ring-purple-400 focus:border-purple-400 block w-full min-w-0 rounded-md sm:text-sm border-gray-600 bg-gray-900"
                  ) %>
                </div>
              </div>

              <div class="sm:col-span-4">
                <label for="about" class="block text-sm font-medium text-gray-200">
                  Stream title
                </label>
                <div class="mt-1">
                  <%= text_input(f, :channel_tagline,
                    class:
                      "bg-gray-950 text-white flex-1 focus:ring-purple-400 focus:border-purple-400 block w-full min-w-0 rounded-md sm:text-sm border-gray-600"
                  ) %>
                  <.error
                    field={:channel_tagline}
                    input_name="user[channel_tagline]"
                    errors={f.errors}
                  />
                </div>
              </div>

              <div class="sm:col-span-4">
                <label for="about" class="block text-sm font-medium text-gray-200">
                  Stream URL
                </label>
                <div class="mt-1">
                  <div class="py-2 border px-3 border-1 bg-gray-950 text-white flex-1 focus:ring-purple-400 focus:border-purple-400 block w-full min-w-0 rounded-md sm:text-sm border-gray-600">
                    <%= "rtmp://#{URI.parse(AlgoraWeb.Endpoint.url()).host}:#{Algora.config([:rtmp_port])}/#{@current_user.stream_key}" %>
                  </div>
                </div>
                <p class="mt-2 text-sm text-gray-400">
                  <%= "Paste into OBS Studio > File > Settings > Stream > Server" %>
                </p>
              </div>
            </div>
          </div>
        </div>

        <div class="pt-5">
          <div class="flex justify-end">
            <button
              type="submit"
              class="ml-3 inline-flex justify-center py-2 px-4 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-purple-600 hover:bg-purple-500 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-purple-400"
            >
              Save
            </button>
          </div>
        </div>
      </.form>
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
    {:ok, assign(socket, current_user: current_user, changeset: changeset)}
  end

  def handle_event("validate", %{"user" => params}, socket) do
    changeset = Accounts.change_settings(socket.assigns.current_user, params)
    {:noreply, assign(socket, changeset: Map.put(changeset, :action, :validate))}
  end

  def handle_event("save", %{"user" => params}, socket) do
    case Accounts.update_settings(socket.assigns.current_user, params) do
      {:ok, user} ->
        {:noreply,
         socket
         |> assign(current_user: user)
         |> put_flash(:info, "settings updated!")}

      {:error, changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  def handle_params(params, _url, socket) do
    {:noreply, socket |> apply_action(socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, _params) do
    socket |> assign(:page_title, "Settings")
  end
end
