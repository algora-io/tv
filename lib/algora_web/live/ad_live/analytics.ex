defmodule AlgoraWeb.AdLive.Analytics do
  use AlgoraWeb, :live_view

  alias Algora.Ads

  @impl true
  def mount(%{"slug" => slug}, _session, socket) do
    ad = Algora.Ads.get_ad_by_slug!(slug)
    stats = fetch_ad_stats(ad)

    {:ok, socket |> assign(ad: ad) |> assign(stats: stats)}
  end

  @impl true
  def handle_params(%{"slug" => slug}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:ad, Ads.get_ad_by_slug!(slug))}
  end

  defp page_title(:show), do: "Show Ad"

  defp fetch_ad_stats(ad) do
    appearances = Algora.Ads.list_appearances(ad)
    content_metrics = Algora.Ads.list_content_metrics(appearances)

    %{
      views: %{
        twitch: content_metrics.twitch_views,
        youtube: content_metrics.youtube_views,
        twitter: content_metrics.twitter_views
      },
      total_views:
        content_metrics.twitch_views + content_metrics.youtube_views +
          content_metrics.twitter_views,
      airtime: calculate_total_airtime(appearances),
      streams: length(appearances),
      creators: length(Enum.uniq_by(appearances, & &1.creator_id))
    }
  end

  defp calculate_total_airtime(appearances) do
    total_seconds =
      Enum.reduce(appearances, 0, fn appearance, acc ->
        acc + (appearance.end_time - appearance.start_time)
      end)

    minutes = div(total_seconds, 60)
    seconds = rem(total_seconds, 60)

    "#{minutes}m #{seconds}s"
  end
end
