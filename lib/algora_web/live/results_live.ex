defmodule AlgoraWeb.ResultsLive do
  use AlgoraWeb, :live_view
  require Logger

  alias Algora.{Library, Cache}

  def render(assigns) do
    ~H"""
    <div class="text-white min-h-screen max-w-7xl mx-auto">
      <div class="flex">
        <div class="flex-1 p-4 space-y-12">
          <div :for={%{video: video, segments: segments} <- @results} class="flex gap-4">
            <.video_thumbnail video={video} class="w-full rounded-2xl" />

            <div>
              <div>
                <h3 class="text-lg font-bold line-clamp-2"><%= video.title %></h3>
                <p class="text-sm text-gray-300"><%= Timex.from_now(video.inserted_at) %></p>
                <div class="mt-2 flex items-center gap-2">
                  <span class="relative flex items-center h-8 w-8 shrink-0 overflow-hidden rounded-full">
                    <img
                      class="aspect-square h-full w-full"
                      alt={video.channel_name}
                      src={video.channel_avatar_url}
                    />
                  </span>
                  <span class="text-sm text-gray-300"><%= video.channel_name %></span>
                </div>
              </div>
              <div class="mt-4 relative">
                <div class="w-full h-full pointer-events-none absolute bg-gradient-to-r from-transparent from-[75%] to-gray-900 rounded-xl">
                </div>
                <div class="bg-white/[7.5%] border border-white/[20%] p-4 rounded-xl flex gap-8 w-[40rem] overflow-x-auto pb-4 -mb-4 scrollbar-thin">
                  <div :for={segment <- segments} class="space-x-2">
                    <div class="w-[28rem]">
                      <p class="text-base font-semibold text-green-400">
                        <%= Library.to_hhmmss(segment.start) %>
                      </p>
                      <p class="mt-2 text-sm"><%= segment.body %></p>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    # TODO: implement properly
    segments = Cache.fetch("tmp/segments", fn -> Library.get_video!(779) |> ML.chunk() end)

    videos = Library.list_videos(150)

    results =
      videos
      |> Enum.map(fn video ->
        %{video: video, segments: Enum.take_random(segments, 3)}
      end)

    {:ok,
     socket
     |> assign(:results, results)}
  end

  defp apply_action(socket, :index, _params) do
    socket |> assign(:page_title, "Results")
  end
end
