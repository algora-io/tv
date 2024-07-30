defmodule AlgoraWeb.AdLive.Analytics do
  use AlgoraWeb, :live_view

  alias Algora.Ads

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:ad, Ads.get_ad!(id))}
  end

  defp page_title(:show), do: "Show Ad"
end
