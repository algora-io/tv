defmodule AlgoraWeb.ContentLive do
  use AlgoraWeb, :live_view

  alias Algora.Ads
  alias Algora.Ads.{ContentMetrics, Appearance, ProductReview}
  alias Algora.Library
  alias AlgoraWeb.LayoutComponent

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
     |> assign(:show_appearance_modal, false)
     |> assign(:show_product_review_modal, false)
     |> assign(:show_content_metrics_modal, false)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-5xl mx-auto space-y-6 p-6">
      <%= for content_metric <- @content_metrics do %>
        <div class="bg-white/5 p-6 ring-1 ring-white/15 rounded-lg space-y-4">
          <div class="flex justify-between items-start">
            <div>
              <div class="text-lg font-semibold"><%= content_metric.video.title %></div>
              <div class="text-sm text-gray-400">
                <%= Calendar.strftime(content_metric.video.inserted_at, "%b %d, %Y, %I:%M %p UTC") %>
              </div>
            </div>
            <div class="flex items-center gap-6 text-sm font-display">
              <.link href={content_metric.twitch_stream_url} class="flex items-center gap-2">
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  width="24"
                  height="24"
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke="currentColor"
                  stroke-width="2"
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  class="icon icon-tabler icons-tabler-outline icon-tabler-brand-twitch"
                >
                  <path stroke="none" d="M0 0h24v24H0z" fill="none" /><path d="M4 5v11a1 1 0 0 0 1 1h2v4l4 -4h5.584c.266 0 .52 -.105 .707 -.293l2.415 -2.414c.187 -.188 .293 -.442 .293 -.708v-8.585a1 1 0 0 0 -1 -1h-14a1 1 0 0 0 -1 1z" /><path d="M16 8l0 4" /><path d="M12 8l0 4" />
                </svg>
                <%= content_metric.twitch_avg_concurrent_viewers || 0 %> CCV / <%= content_metric.twitch_views ||
                  0 %> Views
              </.link>
              <.link href={content_metric.youtube_video_url} class="flex items-center gap-2">
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  width="24"
                  height="24"
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke="currentColor"
                  stroke-width="2"
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  class="icon icon-tabler icons-tabler-outline icon-tabler-brand-youtube"
                >
                  <path stroke="none" d="M0 0h24v24H0z" fill="none" /><path d="M2 8a4 4 0 0 1 4 -4h12a4 4 0 0 1 4 4v8a4 4 0 0 1 -4 4h-12a4 4 0 0 1 -4 -4v-8z" /><path d="M10 9l5 3l-5 3z" />
                </svg>
                <%= content_metric.youtube_views || 0 %> Views
              </.link>
              <.link href={content_metric.twitter_video_url} class="flex items-center gap-2">
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  width="24"
                  height="24"
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke="currentColor"
                  stroke-width="2"
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  class="icon icon-tabler icons-tabler-outline icon-tabler-brand-x"
                >
                  <path stroke="none" d="M0 0h24v24H0z" fill="none" /><path d="M4 4l11.733 16h4.267l-11.733 -16z" /><path d="M4 20l6.768 -6.768m2.46 -2.46l6.772 -6.772" />
                </svg>
                <%= content_metric.twitter_views || 0 %> Views
              </.link>
            </div>
          </div>
          <table class="w-full ring-1 ring-white/5 bg-gray-950/40 rounded-lg">
            <thead>
              <tr>
                <th class="text-sm px-6 py-3 text-left">Ad</th>
                <th class="text-sm px-6 py-3 text-right">Airtime</th>
                <th class="text-sm px-6 py-3 text-right">Blurb</th>
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

          <div class="flex space-x-4">
            <.button phx-click="open_appearance_modal" phx-value-video_id={content_metric.video_id}>
              Add airtime
            </.button>
            <.button
              phx-click="open_product_review_modal"
              phx-value-video_id={content_metric.video_id}
            >
              Add blurb
            </.button>
          </div>
        </div>
      <% end %>

      <div class="bg-white/5 p-6 ring-1 ring-white/15 rounded-lg">
        <.button phx-click="open_content_metrics_modal">Add Content Metrics</.button>
      </div>
    </div>

    <.modal
      :if={@show_appearance_modal}
      id="appearance-modal"
      show
      on_cancel={JS.patch(~p"/admin/content")}
    >
      <.header>Add Airtime</.header>
      <.simple_form for={@new_appearance_form} phx-submit="save_appearance">
        <%= hidden_input(@new_appearance_form, :video_id) %>
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
      </.simple_form>
    </.modal>

    <.modal
      :if={@show_product_review_modal}
      id="product-review-modal"
      show
      on_cancel={JS.patch(~p"/admin/content")}
    >
      <.header>Add Blurb</.header>
      <.simple_form for={@new_product_review_form} phx-submit="save_product_review">
        <%= hidden_input(@new_product_review_form, :video_id) %>
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
        <.input field={@new_product_review_form[:thumbnail_url]} type="text" label="Thumbnail URL" />
        <.button type="submit">Submit</.button>
      </.simple_form>
    </.modal>

    <.modal
      :if={@show_content_metrics_modal}
      id="content-metrics-modal"
      show
      on_cancel={JS.patch(~p"/admin/content")}
    >
      <.header>Add Content Metrics</.header>
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
          phx-change="video_selected"
        />
        <.input
          field={@new_content_metrics_form[:algora_stream_url]}
          type="text"
          label="Algora URL"
          phx-change="url_entered"
          phx-debounce="300"
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

        <.input
          field={@new_content_metrics_form[:twitch_avg_concurrent_viewers]}
          type="number"
          label="Twitch Average CCV"
        />

        <div class="grid grid-cols-3 gap-4">
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
        </div>

        <.button type="submit">Submit</.button>
      </.simple_form>
    </.modal>
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
         )
         |> assign(:show_content_metrics_modal, false)}

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
         |> assign(:show_appearance_modal, false)}

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
         |> assign(:show_product_review_modal, false)}

      {:error, changeset} ->
        {:noreply, assign(socket, :new_product_review_form, to_form(changeset))}
    end
  end

  @impl true
  def handle_event("open_appearance_modal", %{"video_id" => video_id}, socket) do
    {:noreply,
     socket
     |> assign(:show_appearance_modal, true)
     |> assign(
       :new_appearance_form,
       to_form(Ads.change_appearance(%Appearance{video_id: String.to_integer(video_id)}))
     )}
  end

  @impl true
  def handle_event("open_product_review_modal", %{"video_id" => video_id}, socket) do
    {:noreply,
     socket
     |> assign(:show_product_review_modal, true)
     |> assign(
       :new_product_review_form,
       to_form(Ads.change_product_review(%ProductReview{video_id: String.to_integer(video_id)}))
     )}
  end

  @impl true
  def handle_event("open_content_metrics_modal", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_content_metrics_modal, true)
     |> assign(:new_content_metrics_form, to_form(Ads.change_content_metrics(%ContentMetrics{})))}
  end

  @impl true
  def handle_event("video_selected", %{"content_metrics" => %{"video_id" => video_id}}, socket) do
    video =
      if video_id != "",
        do: Enum.find(socket.assigns.videos, &(&1.id == String.to_integer(video_id)))

    url =
      if video, do: "#{AlgoraWeb.Endpoint.url()}/#{video.channel_handle}/#{video_id}", else: ""

    {:noreply,
     socket
     |> assign(
       :new_content_metrics_form,
       to_form(
         Ads.change_content_metrics(%ContentMetrics{video_id: video_id, algora_stream_url: url})
       )
     )}
  end

  @impl true
  def handle_event("url_entered", %{"content_metrics" => %{"algora_stream_url" => url}}, socket) do
    video =
      Enum.find(
        socket.assigns.videos,
        &(url == "#{AlgoraWeb.Endpoint.url()}/#{&1.channel_handle}/#{&1.id}")
      )

    video_id = if video, do: video.id, else: nil

    {:noreply,
     socket
     |> assign(
       :new_content_metrics_form,
       to_form(
         Ads.change_content_metrics(%ContentMetrics{video_id: video_id, algora_stream_url: url})
       )
     )}
  end

  @impl true
  def handle_params(params, _url, socket) do
    LayoutComponent.hide_modal()
    {:noreply, socket |> apply_action(socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :show, _params) do
    socket
    |> assign(:page_title, "Content")
    |> assign(:page_description, "Content")
  end
end
