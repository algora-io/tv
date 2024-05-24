defmodule AlgoraWeb.ShowLive.Show do
  use AlgoraWeb, :live_view

  alias Algora.Shows

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"slug" => slug}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:show, Shows.get_show_by_fields!(slug: slug))}
  end

  defp page_title(:show), do: "Show Show"
  defp page_title(:edit), do: "Edit Show"
end
