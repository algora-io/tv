defmodule AlgoraWeb.AdOverlayLive do
  use AlgoraWeb, :live_view
  require Logger

  alias AlgoraWeb.{LayoutComponent, Presence}
  alias Algora.{Accounts, Library, Ads}

  def render(assigns) do
    ~H"""
    <%= if @ads && length(@ads) > 0 do %>
      <div class="relative">
        <.ad_banner
          ad={@current_ad}
          id="ad-banner-0"
          class={if @show_ad, do: "opacity-100", else: "opacity-0"}
        />
        <.ad_banner ad={@next_ad} id="ad-banner-1" class="opacity-0 pointer-events-none" />
      </div>
    <% end %>
    """
  end

  def mount(%{"channel_handle" => channel_handle} = params, _session, socket) do
    channel =
      Accounts.get_user_by!(handle: channel_handle)
      |> Library.get_channel!()

    ads = Ads.list_active_ads()
    current_ad_index = Ads.get_current_index(ads)
    current_ad = Enum.at(ads, current_ad_index)
    {next_ad, next_index} = get_next_ad(ads, current_ad_index)

    if connected?(socket) do
      Ads.subscribe_to_ads()
      schedule_next_ad()
    end

    {:ok,
     socket
     |> assign(:channel, channel)
     |> assign(:ads, ads)
     |> assign(:current_ad_index, current_ad_index)
     |> assign(:current_ad, current_ad)
     |> assign(:next_ad, next_ad)
     |> assign(:next_ad_index, next_index)
     |> assign(:show_ad, Map.has_key?(params, "test"))
     |> assign(:test_mode, Map.has_key?(params, "test"))}
  end

  def handle_params(params, _url, socket) do
    LayoutComponent.hide_modal()
    {:noreply, socket |> apply_action(socket.assigns.live_action, params)}
  end

  def handle_info(:toggle_ad, %{assigns: %{test_mode: true}} = socket), do: {:noreply, socket}

  def handle_info(:toggle_ad, socket) do
    case socket.assigns.show_ad do
      true ->
        schedule_next_ad()
        {:noreply, assign(socket, :show_ad, false)}

      false ->
        track_impressions(socket.assigns.next_ad, socket.assigns.channel.handle)
        Process.send_after(self(), :toggle_ad, Ads.display_duration())

        {new_next_ad, new_next_index} =
          get_next_ad(socket.assigns.ads, socket.assigns.next_ad_index)

        {:noreply,
         socket
         |> assign(:show_ad, true)
         |> assign(:current_ad, socket.assigns.next_ad)
         |> assign(:current_ad_index, socket.assigns.next_ad_index)
         |> assign(:next_ad, new_next_ad)
         |> assign(:next_ad_index, new_next_index)}
    end
  end

  def handle_info({Ads, %Ads.Events.AdCreated{}}, socket) do
    update_ads_state(socket)
  end

  def handle_info({Ads, %Ads.Events.AdDeleted{}}, socket) do
    update_ads_state(socket)
  end

  def handle_info({Ads, %Ads.Events.AdUpdated{}}, socket) do
    update_ads_state(socket)
  end

  def handle_info(_arg, socket), do: {:noreply, socket}

  defp apply_action(socket, :show, params) do
    channel_name = params["channel_handle"]

    socket
    |> assign(:page_title, channel_name)
    |> assign(:page_description, "Watch #{channel_name} on Algora TV")
  end

  defp schedule_next_ad do
    Process.send_after(self(), :toggle_ad, Ads.time_until_next_slot())
  end

  defp track_impressions(nil, _channel_handle), do: :ok

  defp track_impressions(ad, channel_handle) do
    viewers_count =
      Presence.list_online_users(channel_handle)
      |> Enum.flat_map(fn %{metas: metas} -> metas end)
      |> Enum.filter(fn meta -> meta.id != channel_handle end)
      |> length()

    Ads.track_impressions(%{
      ad_id: ad.id,
      duration: Ads.display_duration(),
      viewers_count: viewers_count
    })
  end

  defp get_next_ad(ads, current_index) do
    next_index = rem(current_index + 1, length(ads))
    {Enum.at(ads, next_index), next_index}
  end

  defp update_ads_state(socket) do
    ads = Ads.list_active_ads()
    current_ad_index = Ads.get_current_index(ads)
    current_ad = Enum.at(ads, current_ad_index)
    {next_ad, next_index} = get_next_ad(ads, current_ad_index)

    {:noreply,
     socket
     |> assign(:ads, ads)
     |> assign(:current_ad_index, current_ad_index)
     |> assign(:current_ad, current_ad)
     |> assign(:next_ad, next_ad)
     |> assign(:next_ad_index, next_index)}
  end
end
