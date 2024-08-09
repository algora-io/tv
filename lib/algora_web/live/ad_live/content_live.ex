defmodule AlgoraWeb.ContentLive do
  use AlgoraWeb, :live_view
  alias Algora.Ads
  alias Algora.Ads.{ContentMetrics, Appearance, ProductReview}

  @impl true
  def mount(_params, _session, socket) do
    content_metrics = Ads.list_content_metrics()

    {:ok,
     socket
     |> assign(:content_metrics, content_metrics)
     |> assign(:new_content_metrics_form, to_form(Ads.change_content_metrics(%ContentMetrics{})))
     |> assign(:new_appearance_form, to_form(Ads.change_appearance(%Appearance{})))
     |> assign(:new_product_review_form, to_form(Ads.change_product_review(%ProductReview{})))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-5xl mx-auto space-y-8 p-8">
      <%= for content_metric <- @content_metrics do %>
        <div class="bg-white/5 p-8 ring-1 ring-white/15 rounded-lg">
          <div class="mb-4">
            <img
              src={content_metric.video.thumbnail_url}
              alt={content_metric.video.title}
              class="max-w-sm w-full h-auto rounded-lg shadow-lg"
            />
          </div>
          <p class="text-lg font-semibold"><%= content_metric.video.title %></p>
          <p class="text-sm text-gray-400">
            <%= Calendar.strftime(content_metric.video.inserted_at, "%b %d, %Y, %I:%M %p UTC") %>
          </p>
          <table class="w-full border-collapse border border-gray-300 mt-4">
            <thead>
              <tr>
                <th class="border border-gray-300 px-4 py-2">Ad</th>
                <th class="border border-gray-300 px-4 py-2">Airtime</th>
                <th class="border border-gray-300 px-4 py-2">Clip From</th>
                <th class="border border-gray-300 px-4 py-2">Clip To</th>
                <th class="border border-gray-300 px-4 py-2">Thumbnail URL</th>
              </tr>
            </thead>
            <tbody>
              <%= for ad_id <- Enum.uniq(Enum.map(content_metric.video.appearances, & &1.ad_id) ++ Enum.map(content_metric.video.product_reviews, & &1.ad_id)) do %>
                <% ad = Ads.get_ad!(ad_id) %>
                <tr>
                  <td class="border border-gray-300 px-4 py-2"><%= ad.slug %></td>
                  <td class="border border-gray-300 px-4 py-2">
                    <%= Enum.map_join(
                      Enum.filter(content_metric.video.appearances, &(&1.ad_id == ad_id)),
                      ", ",
                      & &1.airtime
                    ) %>
                  </td>
                  <td class="border border-gray-300 px-4 py-2">
                    <%= Enum.map_join(
                      Enum.filter(content_metric.video.product_reviews, &(&1.ad_id == ad_id)),
                      ", ",
                      & &1.clip_from
                    ) %>
                  </td>
                  <td class="border border-gray-300 px-4 py-2">
                    <%= Enum.map_join(
                      Enum.filter(content_metric.video.product_reviews, &(&1.ad_id == ad_id)),
                      ", ",
                      & &1.clip_to
                    ) %>
                  </td>
                  <td class="border border-gray-300 px-4 py-2">
                    <%= Enum.map_join(
                      Enum.filter(content_metric.video.product_reviews, &(&1.ad_id == ad_id)),
                      ", ",
                      & &1.thumbnail_url
                    ) %>
                  </td>
                </tr>
              <% end %>
            </tbody>
          </table>

          <.simple_form for={@new_appearance_form} phx-submit="save_appearance">
            <div class="flex items-center gap-4">
              <.input
                type="hidden"
                field={@new_appearance_form[:video_id]}
                value={content_metric.video_id}
              />
              <.input field={@new_appearance_form[:airtime]} type="number" label="Airtime" required />
              <.input field={@new_appearance_form[:ad_id]} type="number" label="Ad ID" required />
              <.button type="submit">Submit</.button>
            </div>
          </.simple_form>

          <.simple_form for={@new_product_review_form} phx-submit="save_product_review">
            <div class="flex items-center gap-4">
              <.input
                type="hidden"
                field={@new_product_review_form[:video_id]}
                value={content_metric.video_id}
              />
              <.input
                field={@new_product_review_form[:clip_from]}
                type="number"
                label="Clip From"
                required
              />
              <.input
                field={@new_product_review_form[:clip_to]}
                type="number"
                label="Clip To"
                required
              />
              <.input
                field={@new_product_review_form[:thumbnail_url]}
                type="text"
                label="Thumbnail URL"
              />
              <.input field={@new_product_review_form[:ad_id]} type="number" label="Ad ID" required />
              <.button type="submit">Submit</.button>
            </div>
          </.simple_form>
        </div>
      <% end %>

      <div class="bg-white/5 p-8 ring-1 ring-white/15 rounded-lg">
        <.simple_form for={@new_content_metrics_form} phx-submit="save_content_metrics">
          <.input
            field={@new_content_metrics_form[:algora_stream_url]}
            type="text"
            label="Algora Stream URL"
          />
          <.input
            field={@new_content_metrics_form[:twitch_stream_url]}
            type="text"
            label="Twitch Stream URL"
          />
          <.input
            field={@new_content_metrics_form[:youtube_video_url]}
            type="text"
            label="YouTube Video URL"
          />
          <.input
            field={@new_content_metrics_form[:twitter_video_url]}
            type="text"
            label="Twitter Video URL"
          />
          <.input
            field={@new_content_metrics_form[:twitch_avg_concurrent_viewers]}
            type="number"
            label="Twitch Avg Concurrent Viewers"
          />
          <.input field={@new_content_metrics_form[:twitch_views]} type="number" label="Twitch Views" />
          <.input
            field={@new_content_metrics_form[:youtube_views]}
            type="number"
            label="YouTube Views"
          />
          <.input
            field={@new_content_metrics_form[:twitter_views]}
            type="number"
            label="Twitter Views"
          />
          <.input
            field={@new_content_metrics_form[:video_id]}
            type="number"
            label="Video ID"
            required
          />
          <.button type="submit">Create Content Metrics</.button>
        </.simple_form>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("save_content_metrics", %{"content_metrics" => params}, socket) do
    case Ads.create_content_metrics(params) do
      {:ok, _content_metrics} ->
        content_metrics = Ads.list_content_metrics()

        {:noreply,
         socket
         |> assign(:content_metrics, content_metrics)
         |> assign(
           :new_content_metrics_form,
           to_form(Ads.change_content_metrics(%ContentMetrics{}))
         )}

      {:error, changeset} ->
        {:noreply, assign(socket, :new_content_metrics_form, to_form(changeset))}
    end
  end

  @impl true
  def handle_event("save_appearance", %{"appearance" => params}, socket) do
    case Ads.create_appearance(params) do
      {:ok, _appearance} ->
        content_metrics = Ads.list_content_metrics()

        {:noreply,
         socket
         |> assign(:content_metrics, content_metrics)
         |> assign(:new_appearance_form, to_form(Ads.change_appearance(%Appearance{})))}

      {:error, changeset} ->
        {:noreply, assign(socket, :new_appearance_form, to_form(changeset))}
    end
  end

  @impl true
  def handle_event("save_product_review", %{"product_review" => params}, socket) do
    case Ads.create_product_review(params) do
      {:ok, _product_review} ->
        content_metrics = Ads.list_content_metrics()

        {:noreply,
         socket
         |> assign(:content_metrics, content_metrics)
         |> assign(:new_product_review_form, to_form(Ads.change_product_review(%ProductReview{})))}

      {:error, changeset} ->
        {:noreply, assign(socket, :new_product_review_form, to_form(changeset))}
    end
  end
end
