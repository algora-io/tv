defmodule AlgoraWeb.COSSGPTLive do
  use AlgoraWeb, :live_view
  alias Algora.{Library, ML, Cache, Util}

  @impl true
  def render(assigns) do
    ~H"""
    <div class="px-4 py-4 lg:py-8 text-white min-h-screen max-w-7xl mx-auto overflow-hidden">
      <form class="max-w-lg mx-auto" phx-submit="search">
        <label for="default-search" class="mb-2 text-sm font-medium sr-only text-white">
          Search
        </label>
        <div class="relative">
          <div class="absolute inset-y-0 start-0 flex items-center ps-3 pointer-events-none">
            <svg
              class="w-4 h-4 text-gray-400"
              aria-hidden="true"
              xmlns="http://www.w3.org/2000/svg"
              fill="none"
              viewBox="0 0 20 20"
            >
              <path
                stroke="currentColor"
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="m19 19-4-4m0-7A7 7 0 1 1 1 8a7 7 0 0 1 14 0Z"
              />
            </svg>
          </div>
          <input
            type="search"
            name="query"
            value={@query}
            autocomplete="off"
            class="block w-full p-4 ps-10 text-sm border rounded-lg border-purple-500 bg-white/[5%] placeholder-gray-400 text-white ring-purple-500 ring-1 focus:ring-2 focus:ring-purple-500 focus:outline-none"
            placeholder="Search..."
            required
          />
          <button
            type="submit"
            class="text-white absolute end-2.5 bottom-2.5 focus:ring-4 focus:outline-none font-medium rounded-lg text-sm px-4 py-2 bg-purple-600 hover:bg-purple-700 focus:ring-purple-800"
          >
            Search
          </button>
        </div>
      </form>
      <div class="mt-4">
        <div class="uppercase text-center text-gray-300 tracking-tight text-xs font-semibold">
          Suggestions
        </div>
        <div class="mt-4 flex flex-wrap gap-2 justify-center max-w-3xl mx-auto">
          <div
            :for={
              suggestion_group <- [
                [
                  "Business models and pricing",
                  "Enterprise sales",
                  "Building an MVP",
                  "How to get your first customers"
                ],
                [
                  "Fundraising",
                  "B2B startup metrics",
                  "Setting KPIs and goals",
                  "Developer marketing"
                ]
              ]
            }
            class="-ml-2 -mt-2 p-2 z-10 flex md:justify-center whitespace-nowrap md:flex-wrap gap-4 overflow-x-auto md:overflow-x-hidden"
          >
            <button
              :for={suggestion <- suggestion_group}
              phx-click="search"
              phx-value-query={suggestion}
              class="bg-white/10 text-gray-200 font-medium text-sm px-3 py-2 ring-1 ring-white/20 shadow-inner inline-flex rounded-lg hover:ring-white/25 hover:bg-white/5 hover:text-white transition-colors"
            >
              <%= suggestion %>
            </button>
          </div>
        </div>
      </div>
      <div class="space-y-4 lg:space-y-8 mt-4 lg:mt-8">
        <div :if={@task} class="flex-1 space-y-4 lg:space-y-8">
          <div :for={_ <- 1..2} class="gap-8 hidden lg:flex">
            <div class="w-1/2 rounded-2xl aspect-video bg-white/20 animate-pulse"></div>
            <div class="w-1/2 rounded-2xl aspect-video bg-white/20 animate-pulse"></div>
          </div>
          <div :for={_ <- 1..3} class="gap-8 lg:hidden flex">
            <div class="w-full rounded-2xl aspect-video bg-white/20 animate-pulse lg:hidden"></div>
          </div>
        </div>
        <div :if={@results} class="flex-1 space-y-8">
          <div
            :for={%{video: video, segments: segments} <- @results}
            class="flex flex-col lg:flex-row gap-8"
          >
            <.link navigate={video_url(video, Enum.at(segments, 0))} class="w-full shrink-0 lg:shrink">
              <.video_thumbnail video={video} class="w-full rounded-2xl" />
            </.link>
            <div>
              <div>
                <.link
                  navigate={video_url(video, Enum.at(segments, 0))}
                  class="text-lg font-bold line-clamp-2"
                >
                  <%= video.title %>
                </.link>
                <p class="text-sm text-gray-300"><%= Timex.from_now(video.inserted_at) %></p>
                <.link navigate={"/#{video.channel_handle}"} class="mt-2 flex items-center gap-2">
                  <span class="relative flex items-center h-8 w-8 shrink-0 overflow-hidden rounded-full">
                    <img
                      class="aspect-square h-full w-full"
                      alt={video.channel_name}
                      src={video.channel_avatar_url}
                    />
                  </span>
                  <span class="text-sm text-gray-300"><%= video.channel_name %></span>
                </.link>
              </div>
              <div class="mt-4 relative">
                <div class="w-full h-full pointer-events-none absolute bg-gradient-to-r from-transparent from-[75%] to-gray-900 rounded-xl">
                </div>
                <div class="bg-white/[7.5%] border border-white/[20%] p-4 rounded-xl flex gap-8 w-[calc(100vw-2rem)] md:hidden lg:flex lg:w-[22rem] xl:w-[40rem] overflow-x-auto pb-4 -mb-4 scrollbar-thin">
                  <.link
                    :for={segment <- segments}
                    class="space-x-2"
                    navigate={video_url(video, segment)}
                  >
                    <div class="w-[66vw] lg:w-[20rem] xl:w-[28rem]">
                      <p class="text-base font-semibold text-green-400">
                        <%= Library.to_hhmmss(segment.start) %>
                      </p>
                      <p class="mt-2 text-sm">
                        <span
                          :for={word <- segment.body |> String.split(~r/\s/)}
                          class={[matches_query?(@query_words, word) && "text-green-300 font-medium"]}
                        >
                          <%= word %>
                        </span>
                      </p>
                    </div>
                  </.link>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp video_url(video, segment) do
    params =
      case segment do
        nil -> ""
        s -> "?t=#{trunc(s.start)}"
      end

    "/#{video.channel_handle}/#{video.id}#{params}"
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, socket |> apply_action(socket.assigns.live_action, params)}
  end

  @impl true
  def handle_event("search", %{"query" => query}, socket) do
    {:noreply, socket |> push_patch(to: ~p"/cossgpt?#{%{query: query}}")}
  end

  @impl true
  def handle_info({ref, result}, socket) when socket.assigns.task.ref == ref do
    {:noreply, assign(socket, task: nil, results: result)}
  end

  def handle_info(_, socket) do
    {:noreply, socket}
  end

  defp apply_action(socket, :index, params) do
    socket =
      case params["query"] || "" do
        "" ->
          socket
          |> assign(
            query: nil,
            query_words: nil,
            task: nil,
            results: nil
          )

        query ->
          socket
          |> assign(
            query: query,
            query_words: query |> String.split(~r/\s/) |> Enum.map(&normalize_word/1),
            task: Task.async(fn -> fetch_results(query) end),
            results: nil
          )
      end

    socket
    |> assign(
      page_title: "COSSgpt",
      page_image: "#{AlgoraWeb.Endpoint.url()}/images/og/cossgpt.png"
    )
  end

  defp fetch_results(query) do
    [%{"embedding" => embedding}] =
      Cache.fetch("embeddings/#{Slug.slugify(query)}", fn ->
        ML.create_embedding(query)
      end)

    index = ML.load_index!()

    segments = ML.get_relevant_chunks(index, embedding)

    to_result = fn video ->
      %{
        video: video,
        segments: segments |> Enum.filter(fn s -> s.video_id == video.id end)
      }
    end

    segments
    |> Enum.map(fn %Library.Segment{video_id: video_id} -> video_id end)
    |> Enum.uniq()
    |> Library.list_videos_by_ids()
    |> Enum.map(to_result)
  end

  defp normalize_word(s) do
    s
    |> String.replace(~r/[^A-Za-z0-9]/, "")
    |> String.downcase()
  end

  defp matches_query?(query_words, s) do
    query_words
    |> Enum.any?(fn s2 ->
      s1 = normalize_word(s)

      String.length(s1) >= 3 and
        String.length(s2) >= 3 and
        (String.contains?(s1, s2) or String.contains?(s2, s1)) and
        !Util.is_common_word(s1) and
        !Util.is_common_word(s2)
    end)
  end
end
