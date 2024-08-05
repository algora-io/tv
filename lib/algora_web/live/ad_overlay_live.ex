defmodule AlgoraWeb.AdOverlayLive do
  use AlgoraWeb, :live_view
  require Logger

  alias AlgoraWeb.{LayoutComponent, Presence}
  alias Algora.{Accounts, Library, Ads}

  def render(assigns) do
    ~H"""
    <%= if @ads && length(@ads) > 0 do %>
      <img
        src={@current_ad.composite_asset_url}
        alt={@current_ad.website_url}
        class={"box-content w-[1092px] h-[135px] object-cover border-[4px] border-[#62feb5] rounded-xl transition-opacity  duration-1000 #{if @show_ad, do: "opacity-100", else: "opacity-0"}"}
      />
    <% end %>
    """
  end

  def mount(%{"channel_handle" => channel_handle} = params, _session, socket) do
    channel =
      Accounts.get_user_by!(handle: channel_handle)
      |> Library.get_channel!()

    ads = Ads.list_ads()
    current_ad_index = get_current_ad_index(ads)
    current_ad = Enum.at(ads, current_ad_index)

    if connected?(socket) do
      schedule_next_ad()
    end

    {:ok,
     socket
     |> assign(:channel, channel)
     |> assign(:ads, ads)
     |> assign(:current_ad_index, current_ad_index)
     |> assign(:current_ad, current_ad)
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
        {next_ad, next_index} = get_next_ad(socket.assigns.ads, socket.assigns.current_ad_index)
        track_impressions(next_ad, socket.assigns.channel.handle)
        Process.send_after(self(), :toggle_ad, Ads.display_duration())

        {:noreply,
         socket
         |> assign(:show_ad, true)
         |> assign(:current_ad_index, next_index)
         |> assign(:current_ad, next_ad)}
    end
  end

  def handle_info(_arg, socket), do: {:noreply, socket}

  defp apply_action(socket, :show, params) do
    channel_name = params["channel_handle"]

    socket
    |> assign(:page_title, channel_name)
    |> assign(:page_description, "Watch #{channel_name} on Algora TV")
  end

  defp schedule_next_ad do
    Process.send_after(self(), :toggle_ad, Ads.time_until_next_ad_slot())
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

  defp get_current_ad_index(ads) do
    :os.system_time(:millisecond)
    |> div(Ads.rotation_interval())
    |> rem(length(ads))
  end

  defp get_next_ad(ads, current_index) do
    next_index = rem(current_index + 1, length(ads))
    {Enum.at(ads, next_index), next_index}
  end
end
