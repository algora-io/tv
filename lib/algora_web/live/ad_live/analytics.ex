defmodule AlgoraWeb.AdLive.Analytics do
  use AlgoraWeb, :live_view
  alias AlgoraWeb.Components.TechIcon
  alias AlgoraWeb.RTMPDestinationIconComponent

  alias Algora.{Ads, Library}
  alias AlgoraWeb.PlayerComponent

  @impl true
  def mount(%{"slug" => slug}, _session, socket) do
    ad = Ads.get_ad_by_slug!(slug)

    %{
      stats: stats,
      appearances: appearances,
      product_reviews: product_reviews,
      product_review: product_review
    } = fetch_ad_stats(ad)

    blurb =
      if product_review,
        do: %{
          video: Library.get_video!(product_review.video_id),
          current_time: product_review.clip_from
        }

    if connected?(socket) do
      if blurb do
        send_update(PlayerComponent, %{
          id: "analytics-player",
          video: blurb.video,
          current_user: socket.assigns.current_user,
          current_time: blurb.current_time
        })
      end
    end

    {:ok,
     socket
     |> assign(ad: ad)
     |> assign(stats: stats)
     |> assign(appearances: appearances)
     |> assign(product_review: product_review)
     |> assign(product_reviews: product_reviews)
     |> assign(blurb: blurb)}
  end

  @impl true
  def handle_info(_arg, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    socket =
      cond do
        socket.assigns.ad.og_image_url ->
          assign(socket, :page_image, socket.assigns.ad.og_image_url)

        socket.assigns.product_review ->
          assign(socket, :page_image, socket.assigns.product_review.thumbnail_url)

        true ->
          socket
      end

    {:noreply,
     socket
     |> assign(:page_title, socket.assigns.ad.name)
     |> assign(
       :page_description,
       "Discover the appearances of #{socket.assigns.ad.name} in livestreams and videos"
     )}
  end

  defp fetch_ad_stats(ad) do
    appearances = Ads.list_appearances(ad)
    content_metrics = Ads.list_content_metrics(appearances)

    product_reviews =
      Ads.list_product_reviews(ad) |> Enum.sort_by(&(&1.clip_to - &1.clip_from), :desc)

    twitch_views = Enum.reduce(content_metrics, 0, fn cm, acc -> acc + cm.twitch_views end)
    youtube_views = Enum.reduce(content_metrics, 0, fn cm, acc -> acc + cm.youtube_views end)
    twitter_views = Enum.reduce(content_metrics, 0, fn cm, acc -> acc + cm.twitter_views end)

    tech_stack_data =
      appearances
      |> group_data_by_tech_stack(content_metrics)
      |> Enum.sort_by(fn {_, d} -> d.views end, :desc)

    product_review = List.first(product_reviews)

    views =
      %{
        "Twitch" => twitch_views,
        "YouTube" => youtube_views,
        "Twitter" => twitter_views
      }
      |> Enum.sort_by(fn {_, v} -> v end, :desc)

    %{
      stats: %{
        views: views,
        total_views: twitch_views + youtube_views + twitter_views,
        airtime: calculate_total_airtime(appearances),
        streams: length(appearances),
        creators: length(Enum.uniq_by(appearances, & &1.video.user.id)),
        tech_stack_data: tech_stack_data
      },
      appearances: appearances,
      product_reviews: product_reviews,
      product_review: product_review
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
      7 -> "TypeScript"
      8 -> "TypeScript"
      109 -> "TypeScript"
      307 -> "PHP"
      588 -> "Elixir"
      _ -> "Other"
    end
  end

  defp calculate_total_airtime(appearances) do
    appearances
    |> Enum.reduce(0, fn appearance, acc -> acc + appearance.airtime end)
    |> format_duration()
  end

  defp format_duration(seconds) do
    hours = div(seconds, 3600)
    minutes = div(rem(seconds, 3600), 60)
    remaining_seconds = rem(seconds, 60)

    cond do
      hours > 0 -> "#{hours}h #{minutes}m #{remaining_seconds}s"
      minutes > 0 -> "#{minutes}m #{remaining_seconds}s"
      true -> "#{remaining_seconds}s"
    end
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
