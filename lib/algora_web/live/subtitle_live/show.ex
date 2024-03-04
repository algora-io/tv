defmodule AlgoraWeb.SubtitleLive.Show do
  use AlgoraWeb, :live_view

  alias Algora.Library

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:subtitle, Library.get_subtitle!(id))}
  end

  defp page_title(:show), do: "Show Subtitle"
  defp page_title(:edit), do: "Edit Subtitle"
end
