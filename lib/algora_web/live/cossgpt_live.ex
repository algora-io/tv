defmodule AlgoraWeb.COSSGPTLive do
  use AlgoraWeb, :live_view
  require Logger

  alias Algora.{Library, ML, Cache}

  @impl true
  def render(assigns) do
    ~H"""
    <div class="text-white min-h-screen max-w-7xl mx-auto">
      <form class="mt-8 max-w-lg mx-auto" phx-submit="search">
        <label
          for="default-search"
          class="mb-2 text-sm font-medium text-gray-900 sr-only dark:text-white"
        >
          Search
        </label>
        <div class="relative">
          <div class="absolute inset-y-0 start-0 flex items-center ps-3 pointer-events-none">
            <svg
              class="w-4 h-4 text-gray-500 dark:text-gray-400"
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
            class="block w-full p-4 ps-10 text-sm text-gray-900 border border-gray-300 rounded-lg bg-gray-50 focus:ring-purple-500 focus:border-purple-500 dark:bg-white/[7.5%] dark:border-gray-600 dark:placeholder-gray-400 dark:text-white dark:focus:ring-purple-500 dark:focus:border-purple-500"
            placeholder="Search..."
            required
          />
          <button
            type="submit"
            class="text-white absolute end-2.5 bottom-2.5 bg-purple-700 hover:bg-purple-800 focus:ring-4 focus:outline-none focus:ring-purple-300 font-medium rounded-lg text-sm px-4 py-2 dark:bg-purple-600 dark:hover:bg-purple-700 dark:focus:ring-purple-800"
          >
            Search
          </button>
        </div>
      </form>
      <div class="flex mt-8">
        <div :if={@results} class="flex-1 p-4 space-y-8 shrink-0">
          <div :for={%{video: video, segments: segments} <- @results} class="flex gap-8">
            <.link navigate={"/#{video.channel_handle}/#{video.id}"} class="w-full">
              <.video_thumbnail video={video} class="w-full rounded-2xl" />
            </.link>
            <div>
              <div>
                <.link
                  navigate={"/#{video.channel_handle}/#{video.id}"}
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
                <div class="bg-white/[7.5%] border border-white/[20%] p-4 rounded-xl flex gap-8 w-[40rem] overflow-x-auto pb-4 -mb-4 scrollbar-thin">
                  <.link
                    :for={segment <- segments}
                    class="space-x-2"
                    navigate={"/#{video.channel_handle}/#{video.id}?t=#{trunc(segment.start)}"}
                  >
                    <div class="w-[28rem]">
                      <p class="text-base font-semibold text-green-400">
                        <%= Library.to_hhmmss(segment.start) %>
                      </p>
                      <p class="mt-2 text-sm"><%= segment.body %></p>
                    </div>
                  </.link>
                </div>
              </div>
            </div>
          </div>
        </div>
        <div :if={@task} class="flex-1 p-4 space-y-8">
          <div :for={_ <- 1..2} class="flex gap-8">
            <div class="w-1/2 rounded-2xl aspect-video bg-white/10 animate-pulse"></div>
            <div class="w-1/2 rounded-2xl aspect-video bg-white/10 animate-pulse"></div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket |> assign(text: nil, task: nil, results: nil)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, socket |> apply_action(socket.assigns.live_action, params)}
  end

  @impl true
  def handle_event("search", %{"query" => query}, socket) do
    case query do
      "" ->
        {:noreply, assign(socket, text: nil, task: nil, results: nil)}

      text ->
        task =
          Task.async(fn ->
            Cache.refetch("tmp/results", fn ->
              %{"embedding" => embedding} = ML.create_embedding(query) |> Enum.at(0)

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
            end)
          end)

        {:noreply, assign(socket, text: text, task: task, results: nil)}
    end
  end

  @impl true
  def handle_info({ref, result}, socket) when socket.assigns.task.ref == ref do
    {:noreply, assign(socket, task: nil, results: result)}
  end

  def handle_info(_, socket) do
    {:noreply, socket}
  end

  defp apply_action(socket, :index, _params) do
    socket |> assign(:page_title, "Results")
  end
end
