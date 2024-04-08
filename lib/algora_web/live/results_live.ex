defmodule AlgoraWeb.ResultsLive do
  use AlgoraWeb, :live_view
  require Logger

  alias Algora.Library

  def render(assigns) do
    ~H"""
    <div class="text-white min-h-screen max-w-5xl mx-auto">
      <div class="flex">
        <div class="flex-1 p-4 space-y-12">
          <div :for={video <- @videos} class="grid grid-cols-2 gap-4">
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
                <div class="flex items-center">
                  <span class="relative flex h-10 w-10 shrink-0 overflow-hidden rounded-full">
                    <img
                      class="aspect-square h-full w-full"
                      alt={video.channel_name}
                      src={video.channel_avatar_url}
                    />
                  </span>
                  <span class="ml-2"><%= video.channel_name %></span>
                </div>
                <h3 class="text-lg font-bold mt-2"><%= video.title %></h3>
                <p class="text-sm text-gray-400"><%= Timex.from_now(video.inserted_at) %></p>
                <p :if={video.description} class="mt-2 text-sm line-clamp-2">
                  <%= video.description %>
                </p>
              </div>
            </div>
            <div class="bg-gray-800 p-4 rounded-xl space-y-4">
              <h4 class="text-sm font-bold">Matching segments</h4>
              <div class="flex flex-col space-y-4">
                <div :for={_ <- 1..5} class="flex items-center space-x-2">
                  <img
                    src={video.thumbnail_url}
                    alt="Chapter thumbnail"
                    class="rounded-xl aspect-video object-cover h-10"
                  />
                  <div>
                    <p class="text-sm">Intro</p>
                    <p class="text-xs text-gray-400">0:00</p>
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
    videos = Library.list_videos(150)

    {:ok,
     socket
     |> assign(:videos, videos)}
  end

  defp apply_action(socket, :index, _params) do
    socket |> assign(:page_title, "Results")
  end
end
