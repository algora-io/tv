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
         |> put_flash(:info, "Settings updated successfully")}

      {:error, changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  def handle_event("reset_stream_key", _, socket) do
    case Accounts.gen_stream_key(socket.assigns.current_user) do
      {:ok, user} ->
        {:noreply,
         socket
         |> assign(current_user: user)
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
