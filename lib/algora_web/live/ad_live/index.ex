defmodule AlgoraWeb.AdLive.Index do
  use AlgoraWeb, :live_view

  alias Algora.Ads
  alias Algora.Ads.Ad

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :ads, Ads.list_ads())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Ad")
    |> assign(:ad, Ads.get_ad!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Ad")
    |> assign(:ad, %Ad{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Ads")
    |> assign(:ad, nil)
  end

  @impl true
  def handle_info({AlgoraWeb.AdLive.FormComponent, {:saved, ad}}, socket) do
    {:noreply, stream_insert(socket, :ads, ad)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    ad = Ads.get_ad!(id)
    {:ok, _} = Ads.delete_ad(ad)

    {:noreply, stream_delete(socket, :ads, ad)}
  end
end
