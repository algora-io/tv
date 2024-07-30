defmodule AlgoraWeb.AdOverlayLive do
  use AlgoraWeb, :live_view
  require Logger

  alias AlgoraWeb.{LayoutComponent}

  @ad_interval :timer.seconds(10)
  @ad_display_duration :timer.seconds(5)

  def render(assigns) do
    ~H"""
    <div class={"w-[900px] aspect-[1022/150] overflow-hidden rounded-xl transition-opacity duration-1000 #{if @show_ad, do: "opacity-100", else: "opacity-0"}"}>
      <%= if @ad do %>
        <img src={@ad.composite_asset_url} alt={@ad.website_url} />
      <% else %>
        <div class="w-full h-full bg-gray-800 flex items-center justify-center">
          <p class="text-gray-400">No ad available</p>
        </div>
      <% end %>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    ad = Algora.Ads.list_ads() |> List.first()
    if connected?(socket), do: schedule_ad_toggle(@ad_interval)
    {:ok, socket |> assign(:ad, ad) |> assign(:show_ad, false)}
  end

  def handle_params(params, _url, socket) do
    LayoutComponent.hide_modal()
    {:noreply, socket |> apply_action(socket.assigns.live_action, params)}
  end

  def handle_info(:toggle_ad, socket) do
    if socket.assigns.show_ad do
      schedule_ad_toggle(@ad_interval)
      {:noreply, assign(socket, :show_ad, false)}
    else
      schedule_ad_toggle(@ad_display_duration)
      {:noreply, assign(socket, :show_ad, true)}
    end
  end

  def handle_info(_arg, socket), do: {:noreply, socket}

  defp apply_action(socket, :show, params) do
    channel_name = params["channel_handle"]

    socket
    |> assign(:page_title, channel_name)
    |> assign(:page_description, "Watch #{channel_name} on Algora TV")
  end

  defp schedule_ad_toggle(interval) do
    Process.send_after(self(), :toggle_ad, interval)
  end
end
