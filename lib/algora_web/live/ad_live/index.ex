defmodule AlgoraWeb.AdLive.Index do
  use AlgoraWeb, :live_view

  alias Algora.Ads
  alias Algora.Ads.Ad

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      schedule_next_rotation()
    end

    next_slot = Ads.next_slot()

    ads =
      Ads.list_ads()
      |> Ads.rotate_ads()
      |> Enum.with_index(-1)
      |> Enum.map(fn {ad, index} ->
        %{
          ad
          | scheduled_for: DateTime.add(next_slot, index * Ads.rotation_interval(), :millisecond)
        }
      end)

    {:ok,
     socket
     |> stream(:ads, ads)
     |> assign(:next_slot, Ads.next_slot())}
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
  def handle_info(:rotate_ads, socket) do
    schedule_next_rotation()

    next_slot = Ads.next_slot()

    rotated_ads =
      socket.assigns.ads
      |> Ads.rotate_ads(1)
      |> Enum.with_index(-1)
      |> Enum.map(fn {ad, index} ->
        %{
          ad
          | scheduled_for: DateTime.add(next_slot, index * Ads.rotation_interval(), :millisecond)
        }
      end)

    {:noreply,
     socket
     |> stream(:ads, rotated_ads)
     |> assign(:next_slot, Ads.next_slot())}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    ad = Ads.get_ad!(id)
    {:ok, _} = Ads.delete_ad(ad)
    Ads.broadcast_ad_deleted!(ad)

    {:noreply, stream_delete(socket, :ads, ad)}
  end

  defp schedule_next_rotation do
    Process.send_after(self(), :rotate_ads, Ads.time_until_next_slot())
  end
end
