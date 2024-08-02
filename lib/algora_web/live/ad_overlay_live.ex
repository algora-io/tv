defmodule AlgoraWeb.AdOverlayLive do
  use AlgoraWeb, :live_view
  require Logger

  alias AlgoraWeb.{LayoutComponent, Presence}
  alias Algora.Accounts
  alias Algora.Library

  @ad_interval :timer.minutes(10)
  @ad_display_duration :timer.seconds(10)

  def render(assigns) do
    ~H"""
    <%= if @ad do %>
      <img
        src={@ad.composite_asset_url}
        alt={@ad.website_url}
        class={"box-content w-[1092px] h-[135px] object-cover border-[4px] border-[#62feb5] rounded-xl transition-opacity  duration-1000 #{if @show_ad, do: "opacity-100", else: "opacity-0"}"}
      />
    <% end %>
    """
  end

  def mount(%{"channel_handle" => channel_handle}, _session, socket) do
    channel =
      Accounts.get_user_by!(handle: channel_handle)
      |> Library.get_channel!()

    ad = Algora.Ads.list_ads() |> List.first()

    if connected?(socket) do
      schedule_ad_toggle(@ad_interval)
    end

    {:ok,
     socket
     |> assign(:channel, channel)
     |> assign(:ad, ad)
     |> assign(:show_ad, false)}
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
      track_impressions(socket.assigns.ad, socket.assigns.channel.handle)
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

  defp track_impressions(nil, _channel_handle), do: :ok

  defp track_impressions(ad, channel_handle) do
    viewers_count =
      Presence.list_online_users(channel_handle)
      |> Enum.flat_map(fn %{metas: metas} -> metas end)
      |> Enum.filter(fn meta -> meta.id != channel_handle end)
      |> length()

    Algora.Ads.track_impressions(%{
      ad_id: ad.id,
      duration: @ad_display_duration,
      viewers_count: viewers_count
    })
  end
end
