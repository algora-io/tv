defmodule AlgoraWeb.HomepageLive do
  use AlgoraWeb, :live_view

  alias Algora.{Library, Shows}

  def render(assigns) do
    ~H"""
    <div class="mx-auto pt-2 pb-6 px-4 sm:px-6 space-y-6">
      <.header class="py-8">
        <h1 class="text-4xl font-semibold">Open source livestreaming for developers</h1>
        <p class="text-xl font-medium text-gray-200 italic">You'll never ship alone!</p>
      </.header>

      <div :for={{shows, videos} <- @sections}>
        <div class="pt-16">
          <ul role="list" class="grid grid-cols-1 gap-6 sm:grid-cols-2">
            <li :for={show <- shows} class="col-span-1">
              <.link
                navigate={~p"/shows/#{show.slug}"}
                class="flex flex-col rounded-2xl overflow-hidden bg-white/5 ring-1 ring-white/20 text-center shadow-lg relative group"
              >
                <img
                  class="mx-auto absolute inset-0 flex-shrink-0 object-cover h-[12rem] w-full bg-gray-950"
                  src={show.image_url}
                  alt=""
                />
                <div class="absolute h-[12rem] w-full inset-0 bg-gradient-to-b from-transparent to-80% to-gray-950/80" />
                <div class="relative text-left">
                  <div class="flex flex-1 flex-col">
                    <div class="px-2 mt-[8rem] flex items-center gap-4">
                      <img
                        class="h-[8rem] w-[8rem] rounded-full ring-4 ring-white"
                        src={show.channel_avatar_url}
                        alt=""
                      />
                      <div>
                        <h3 class="mt-auto text-3xl font-semibold text-white [text-shadow:#000_10px_5px_10px]">
                          <%= show.title %>
                        </h3>
                        <dl class="mt-1 flex flex-col">
                          <dt class="sr-only">Bio</dt>
                          <dd class="text-base text-gray-300 font-semibold line-clamp-1">
                            <%= show.channel_name %>
                          </dd>
                        </dl>
                      </div>
                    </div>

                    <div class="mt-[2rem] -mb-2 flex gap-8 overflow-x-scroll scrollbar-thin">
                      <div
                        :for={video <- @show_eps |> Enum.filter(fn v -> v.show_id == show.id end)}
                        class="max-w-xs shrink-0 w-full"
                      >
                        <div class="truncate" href={~p"/#{video.channel_handle}/#{video.id}"}>
                          <.video_thumbnail video={video} class="rounded-2xl" />
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </.link>
            </li>
          </ul>
        </div>

        <div class="pt-16">
          <div class="pt-8 gap-8 grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3">
            <.video_entry :for={video <- videos} video={video} />
          </div>
        </div>
      </div>

      <div :if={length(@leftover_videos) > 0} class="pt-16">
        <div class="pt-8 gap-8 grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3">
          <.video_entry :for={video <- @leftover_videos} video={video} />
        </div>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    shows = Shows.list_shows()
    show_eps = shows |> Enum.map(fn s -> s.id end) |> Library.list_videos_by_show_ids()

    show_sections = shows |> Enum.chunk_every(2)
    video_sections = Library.list_videos(150) |> Enum.chunk_every(6)

    num_sections = max(min(length(show_sections), length(video_sections)), 0)

    {shows, leftover_shows} = show_sections |> Enum.split(num_sections)
    {videos, leftover_videos} = video_sections |> Enum.split(num_sections)

    sections = Enum.zip(shows, videos)

    dbg(sections)

    {:ok,
     socket
     |> assign(:show_eps, show_eps)
     |> assign(:sections, sections)
     |> assign(:leftover_videos, Enum.concat(leftover_videos))
     |> assign(:leftover_shows, Enum.concat(leftover_shows))}
  end

  def handle_params(params, _url, socket) do
    {:noreply, socket |> apply_action(socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :show, _params) do
    socket |> assign(:page_title, nil)
  end
end
