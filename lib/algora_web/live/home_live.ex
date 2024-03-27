defmodule AlgoraWeb.HomeLive do
  use AlgoraWeb, :live_view
  require Logger

  alias Algora.Library

  def render(assigns) do
    ~H"""
    <div class="-mt-16 px-4">
      <div :for={{shorts, videos} <- @sections}>
        <div class="pt-16">
          <h2 class="text-white text-xl font-semibold px-8 sr-only">
            Videos
          </h2>
          <div class="pt-8 gap-8 grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3">
            <.video_entry :for={video <- videos} video={video} />
          </div>
        </div>

        <div class="pt-16">
          <h2 class="text-white text-xl font-bold flex items-center gap-1">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="h-8 w-8"
              width="24"
              height="24"
              viewBox="0 0 24 24"
              stroke-width="1.5"
              stroke="currentColor"
              fill="none"
              stroke-linecap="round"
              stroke-linejoin="round"
            ><path stroke="none" d="M0 0h24v24H0z" fill="none" /><path d="M13 3l0 7l6 0l-8 11l0 -7l-6 0l8 -11" /></svg>Shorts
          </h2>
          <div class="pt-4 gap-8 grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-6">
            <.short_entry :for={video <- shorts} id={"short-#{video.id}"} video={video} />
          </div>
        </div>
      </div>

      <div :if={length(@leftover_videos) > 0} class="pt-16">
        <h2 class="text-white text-xl font-semibold px-8 sr-only">
          Videos
        </h2>
        <div class="pt-8 gap-8 grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3">
          <.video_entry :for={video <- @leftover_videos} video={video} />
        </div>
      </div>

      <div :if={length(@leftover_shorts) > 0} class="pt-16">
        <h2 class="text-white text-xl font-bold flex items-center gap-1">
          <svg
            xmlns="http://www.w3.org/2000/svg"
            class="h-8 w-8"
            width="24"
            height="24"
            viewBox="0 0 24 24"
            stroke-width="1.5"
            stroke="currentColor"
            fill="none"
            stroke-linecap="round"
            stroke-linejoin="round"
          ><path stroke="none" d="M0 0h24v24H0z" fill="none" /><path d="M13 3l0 7l6 0l-8 11l0 -7l-6 0l8 -11" /></svg>Shorts
        </h2>
        <div class="pt-4 gap-8 grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-6">
          <.short_entry :for={video <- @leftover_shorts} id={"short-#{video.id}"} video={video} />
        </div>
      </div>
    </div>
    """
  end

  def mount(_map, _session, socket) do
    short_sections = Library.list_shorts(150) |> Enum.chunk_every(6)
    video_sections = Library.list_videos(150) |> Enum.chunk_every(6)

    num_sections = max(min(length(short_sections), length(video_sections)) - 1, 0)

    {shorts, leftover_shorts} = short_sections |> Enum.split(num_sections)
    {videos, leftover_videos} = video_sections |> Enum.split(num_sections)

    sections = Enum.zip(shorts, videos)

    {:ok,
     socket
     |> assign(sections: sections)
     |> assign(leftover_videos: Enum.concat(leftover_videos))
     |> assign(leftover_shorts: Enum.concat(leftover_shorts))}
  end

  def handle_params(params, _url, socket) do
    {:noreply, socket |> apply_action(socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :show, _params) do
    socket |> assign(:page_title, nil)
  end
end
