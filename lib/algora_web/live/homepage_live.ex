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

      <ul role="list" class="grid grid-cols-1 gap-6 sm:grid-cols-2">
        <li :for={show <- @shows} class="col-span-1">
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
                    :for={
                      video <-
                        @videos
                        |> Enum.filter(fn v -> v.show_id == show.id end)
                    }
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
    """
  end

  def mount(_params, _session, socket) do
    shows = Shows.list_shows()
    videos = shows |> Enum.map(fn s -> s.id end) |> Library.list_videos_by_show_ids()

    dbg(videos)

    {:ok,
     socket
     |> assign(:videos, videos)
     |> assign(:shows, shows)}
  end
end
