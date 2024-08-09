defmodule AlgoraWeb.ContentLive do
  use AlgoraWeb, :live_view

  alias Algora.Ads
  alias Algora.Ads.{ContentMetrics, Appearance, ProductReview}
  alias Algora.Library

  @impl true
  def mount(_params, _session, socket) do
    content_metrics = Ads.list_content_metrics()
    ads = Ads.list_ads()
    videos = Library.list_videos()

    {:ok,
     socket
     |> assign(:ads, ads)
     |> assign(:videos, videos)
     |> assign(:content_metrics, content_metrics)
     |> assign(:new_content_metrics_form, to_form(Ads.change_content_metrics(%ContentMetrics{})))
     |> assign(:new_appearance_form, to_form(Ads.change_appearance(%Appearance{})))
     |> assign(:new_product_review_form, to_form(Ads.change_product_review(%ProductReview{})))
     |> assign(:show_appearance_form, -1)
     |> assign(:show_product_review_form, -1)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-5xl mx-auto space-y-6 p-6">
      <%= for content_metric <- @content_metrics do %>
        <div class="bg-white/5 p-6 ring-1 ring-white/15 rounded-lg space-y-4">
          <div>
            <div class="text-lg font-semibold"><%= content_metric.video.title %></div>
            <div class="text-sm text-gray-400">
              <%= Calendar.strftime(content_metric.video.inserted_at, "%b %d, %Y, %I:%M %p UTC") %>
            </div>
          </div>
          <table class="w-full ring-1 ring-white/5 bg-gray-950/40 rounded-lg">
            <thead>
              <tr>
                <th class="text-sm px-6 py-3 text-left">Ad</th>
                <th class="text-sm px-6 py-3 text-right">Airtime</th>
                <th class="text-sm px-6 py-3 text-right">Blurp</th>
                <th class="text-sm px-6 py-3 text-left">Thumbnail</th>
              </tr>
            </thead>
            <tbody>
              <%= for ad_id <- Enum.uniq(Enum.map(content_metric.video.appearances, & &1.ad_id) ++ Enum.map(content_metric.video.product_reviews, & &1.ad_id)) do %>
                <% ad = Ads.get_ad!(ad_id) %>
                <tr>
                  <td class="text-sm px-6 py-3"><%= ad.slug %></td>
                  <td class="text-sm px-6 py-3 text-right tabular-nums">
                    <%= Enum.map_join(
                      Enum.filter(content_metric.video.appearances, &(&1.ad_id == ad_id)),
                      ", ",
                      &Library.to_hhmmss(&1.airtime)
                    ) %>
                  </td>
                  <td class="text-sm px-6 py-3 text-right tabular-nums">
                    <%= Enum.map_join(
                      Enum.filter(content_metric.video.product_reviews, &(&1.ad_id == ad_id)),
                      ", ",
                      &"#{Library.to_hhmmss(&1.clip_from)} - #{Library.to_hhmmss(&1.clip_to)}"
                    ) %>
                  </td>
                  <td class="text-sm px-6 py-3">
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

          <%= if @show_appearance_form == -1 and @show_product_review_form == -1 do %>
            <div class="flex space-x-4">
              <.button phx-click="toggle_appearance_form" phx-value-video_id={content_metric.video_id}>
                Add airtime
              </.button>
              <.button
                phx-click="toggle_product_review_form"
                phx-value-video_id={content_metric.video_id}
              >
                Add blurp
              </.button>
            </div>
          <% end %>

          <%= if @show_appearance_form == content_metric.video_id do %>
            <.simple_form for={@new_appearance_form} phx-submit="save_appearance">
              <.input
                type="hidden"
                field={@new_appearance_form[:video_id]}
                value={content_metric.video_id}
              />
              <div class="grid grid-cols-5 gap-4">
                <.input
                  field={@new_appearance_form[:ad_id]}
                  type="select"
                  label="Ad"
                  prompt="Select an ad"
                  options={Enum.map(@ads, fn ad -> {ad.slug, ad.id} end)}
                />
                <.input field={@new_appearance_form[:airtime]} label="Airtime" placeholder="hh:mm:ss" />
                <div />
                <div />
                <.button type="submit">Submit</.button>
              </div>
            </.simple_form>
          <% end %>

          <%= if @show_product_review_form == content_metric.video_id do %>
            <.simple_form for={@new_product_review_form} phx-submit="save_product_review">
              <.input
                type="hidden"
                field={@new_product_review_form[:video_id]}
                value={content_metric.video_id}
              />
              <div class="grid grid-cols-5 gap-4">
                <.input
                  field={@new_product_review_form[:ad_id]}
                  type="select"
                  label="Ad"
                  prompt="Select an ad"
                  options={Enum.map(@ads, fn ad -> {ad.slug, ad.id} end)}
                />
                <.input
                  field={@new_product_review_form[:clip_from]}
                  type="text"
                  label="Clip From"
                  placeholder="hh:mm:ss"
                />
                <.input
                  field={@new_product_review_form[:clip_to]}
                  type="text"
                  label="Clip To"
                  placeholder="hh:mm:ss"
                />
                <.input
                  field={@new_product_review_form[:thumbnail_url]}
                  type="text"
                  label="Thumbnail URL"
                />
                <.button type="submit">Submit</.button>
              </div>
            </.simple_form>
          <% end %>
        </div>
      <% end %>

      <div class="bg-white/5 p-6 ring-1 ring-white/15 rounded-lg">
        <.simple_form for={@new_content_metrics_form} phx-submit="save_content_metrics">
          <.input
            field={@new_content_metrics_form[:video_id]}
            type="select"
            label="Video"
            options={
              Enum.map(@videos, fn video ->
                {"#{video.title} (#{Calendar.strftime(video.inserted_at, "%b %d, %Y, %I:%M %p UTC")})",
                 video.id}
              end)
            }
            prompt="Select a video"
          />
          <.input
            field={@new_content_metrics_form[:algora_stream_url]}
            type="text"
            label="Algora URL"
          />
          <div class="grid grid-cols-3 gap-4">
            <.input
              field={@new_content_metrics_form[:twitch_stream_url]}
              type="text"
              label="Twitch URL"
            />
            <.input
              field={@new_content_metrics_form[:youtube_video_url]}
              type="text"
              label="YouTube URL"
            />
            <.input
              field={@new_content_metrics_form[:twitter_video_url]}
              type="text"
              label="Twitter URL"
            />
          </div>

          <div class="grid grid-cols-3 gap-4">
            <.input
              field={@new_content_metrics_form[:twitch_avg_concurrent_viewers]}
              type="number"
              label="Twitch Average CCV"
            />
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
          </div>

          <.button type="submit">Submit</.button>
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
    params = Map.update!(params, "airtime", &Library.from_hhmmss/1)

    case Ads.create_appearance(params) do
      {:ok, _appearance} ->
        content_metrics = Ads.list_content_metrics()

        {:noreply,
         socket
         |> assign(:content_metrics, content_metrics)
         |> assign(:new_appearance_form, to_form(Ads.change_appearance(%Appearance{})))
         |> assign(:show_appearance_form, -1)}

      {:error, changeset} ->
        {:noreply, assign(socket, :new_appearance_form, to_form(changeset))}
    end
  end

  @impl true
  def handle_event("save_product_review", %{"product_review" => params}, socket) do
    params = Map.update!(params, "clip_from", &Library.from_hhmmss/1)
    params = Map.update!(params, "clip_to", &Library.from_hhmmss/1)

    case Ads.create_product_review(params) do
      {:ok, _product_review} ->
        content_metrics = Ads.list_content_metrics()

        {:noreply,
         socket
         |> assign(:content_metrics, content_metrics)
         |> assign(:new_product_review_form, to_form(Ads.change_product_review(%ProductReview{})))
         |> assign(:show_product_review_form, -1)}

      {:error, changeset} ->
        {:noreply, assign(socket, :new_product_review_form, to_form(changeset))}
    end
  end

  @impl true
  def handle_event("toggle_appearance_form", %{"video_id" => video_id}, socket) do
    {:noreply,
     socket
     |> assign(:show_appearance_form, String.to_integer(video_id))
     |> assign(
       :new_appearance_form,
       to_form(Ads.change_appearance(%Appearance{video_id: video_id}))
     )}
  end

  @impl true
  def handle_event("toggle_product_review_form", %{"video_id" => video_id}, socket) do
    {:noreply,
     socket
     |> assign(:show_product_review_form, String.to_integer(video_id))
     |> assign(
       :new_product_review_form,
       to_form(Ads.change_product_review(%ProductReview{video_id: video_id}))
     )}
  end
end
