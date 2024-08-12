defmodule AlgoraWeb.AdLive.Analytics do
  use AlgoraWeb, :live_view
  alias AlgoraWeb.Components.TechIcon
  alias AlgoraWeb.RTMPDestinationIconComponent

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

    twitch_views = Enum.reduce(content_metrics, 0, fn cm, acc -> acc + cm.twitch_views end)
    youtube_views = Enum.reduce(content_metrics, 0, fn cm, acc -> acc + cm.youtube_views end)
    twitter_views = Enum.reduce(content_metrics, 0, fn cm, acc -> acc + cm.twitter_views end)

    tech_stack_data = group_data_by_tech_stack(appearances, content_metrics)

    %{
      views: %{
        twitch: twitch_views,
        youtube: youtube_views,
        twitter: twitter_views
      },
      total_views: twitch_views + youtube_views + twitter_views,
      airtime: calculate_total_airtime(appearances),
      streams: length(appearances),
      creators: length(Enum.uniq_by(appearances, & &1.video.user.id)),
      tech_stack_data: tech_stack_data
    }
  end

  defp group_data_by_tech_stack(appearances, content_metrics) do
    appearances
    |> Enum.zip(content_metrics)
    |> Enum.reduce(%{}, fn {appearance, metrics}, acc ->
      tech_stack = get_tech_stack(appearance.video.user.id)
      total_views = metrics.twitch_views + metrics.youtube_views + metrics.twitter_views
      creator = appearance.video.user

      Map.update(acc, tech_stack, %{views: total_views, creators: [creator]}, fn existing ->
        %{
          views: existing.views + total_views,
          creators: [creator | existing.creators] |> Enum.uniq()
        }
      end)
    end)
  end

  # TODO: This is a hack, we need to get the tech stack from the user's profile
  defp get_tech_stack(user_id) do
    case user_id do
      109 -> "TypeScript"
      307 -> "PHP"
      _ -> "Other"
    end
  end

  defp calculate_total_airtime(appearances) do
    total_seconds =
      Enum.reduce(appearances, 0, fn appearance, acc -> acc + appearance.airtime end)

    minutes = div(total_seconds, 60)
    seconds = rem(total_seconds, 60)

    "#{minutes}m #{seconds}s"
  end

  defp format_number(number) when number >= 1_000_000 do
    :io_lib.format("~.1fM", [number / 1_000_000]) |> to_string()
  end

  defp format_number(number) when number >= 1_000 do
    :io_lib.format("~.1fK", [number / 1_000]) |> to_string()
  end

  defp format_number(number), do: to_string(number)

  defp tech_icon(assigns), do: TechIcon.tech_icon(assigns)
  defp source_icon(assigns), do: RTMPDestinationIconComponent.icon(assigns)
end
