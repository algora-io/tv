defmodule AlgoraWeb.ShowLive.Index do
  use AlgoraWeb, :live_view

  alias Algora.Shows
  alias Algora.Shows.Show

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :shows, Shows.list_shows())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Show")
    |> assign(:show, Shows.get_show!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Show")
    |> assign(:show, %Show{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Shows")
    |> assign(:show, nil)
  end

  @impl true
  def handle_info({AlgoraWeb.ShowLive.FormComponent, {:saved, show}}, socket) do
    {:noreply, stream_insert(socket, :shows, show)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    show = Shows.get_show!(id)
    {:ok, _} = Shows.delete_show(show)

    {:noreply, stream_delete(socket, :shows, show)}
  end
end
