defmodule AlgoraWeb.AdLive.Schedule do
  use AlgoraWeb, :live_view

  alias Algora.Ads

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

  defp apply_action(socket, :schedule, _params) do
    socket
    |> assign(:page_title, "Ads schedule")
    |> assign(:ad, nil)
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

  defp schedule_next_rotation do
    Process.send_after(self(), :rotate_ads, Ads.time_until_next_slot())
  end
end
