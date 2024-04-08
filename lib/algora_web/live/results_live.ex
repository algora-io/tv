defmodule AlgoraWeb.ResultsLive do
  use AlgoraWeb, :live_view
  require Logger

  alias Algora.{Library, Cache}

  def render(assigns) do
    ~H"""
    <div class="text-white min-h-screen max-w-5xl mx-auto">
      <div class="flex">
        <div class="flex-1 p-4 space-y-12">
          <div :for={%{video: video, segments: segments} <- @results} class="grid grid-cols-2 gap-4">
            <div>
              <img
                src={video.thumbnail_url}
                alt={video.title}
                class="w-full h-auto rounded-xl"
                width="320"
                height="180"
                style="aspect-ratio: 320 / 180; object-fit: cover;"
              />
              <div class="mt-4">
                <div class="flex">
                  <span class="relative flex h-12 w-12 shrink-0 overflow-hidden rounded-full">
                    <img
                      class="aspect-square h-full w-full"
                      alt={video.channel_name}
                      src={video.channel_avatar_url}
                    />
                  </span>
                  <div class="ml-4">
                    <h3 class="text-lg font-bold line-clamp-2"><%= video.title %></h3>
                    <span class="text-sm text-gray-300"><%= video.channel_name %></span>
                    <p class="text-sm text-gray-300"><%= Timex.from_now(video.inserted_at) %></p>
                  </div>
                </div>
              </div>
            </div>
            <div class="bg-gray-800 p-4 rounded-xl space-y-4">
              <h4 class="text-sm font-bold">Matching segments</h4>
              <div class="flex flex-col space-y-4">
                <div :for={segment <- segments} class="flex space-x-2">
                  <img
                    src={video.thumbnail_url}
                    alt="Chapter thumbnail"
                    class="rounded-md aspect-video object-cover h-10"
                  />
                  <div>
                    <p class="text-base font-semibold text-green-400">
                      <%= Library.to_hhmmss(segment.start) %>
                    </p>
                    <p class="text-sm"><%= segment.body %></p>
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
