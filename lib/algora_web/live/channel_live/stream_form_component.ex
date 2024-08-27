defmodule AlgoraWeb.ChannelLive.StreamFormComponent do
  use AlgoraWeb, :live_component

  alias Algora.Accounts

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
end
