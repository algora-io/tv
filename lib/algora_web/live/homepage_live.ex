defmodule AlgoraWeb.HomepageLive do
  use AlgoraWeb, :live_view

  alias Algora.{Library, Shows}

  def render(assigns) do
    ~H"""
    <div class="mx-auto pt-2 pb-6 px-4 sm:px-6 space-y-6">
      <.header class="pt-8">
        <h1 class="text-4xl font-semibold">Livestreaming for developers</h1>
        <p class="text-xl font-medium text-gray-200 italic">You'll never ship alone!</p>
      </.header>

      <div>
        <ul role="list" class="grid grid-cols-1 gap-12 sm:grid-cols-2">
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
                  <div class="px-4 mt-[8rem] flex-col sm:flex-row flex sm:items-center gap-4">
                    <img
                      class="h-[8rem] w-[8rem] rounded-full ring-4 ring-white shrink-0"
                      src={show.channel_avatar_url}
                      alt=""
                    />
                    <div>
                      <h3 class="mt-auto text-3xl font-semibold text-white [text-shadow:#000_10px_5px_10px] line-clamp-2">
                        <%= show.title %>
                      </h3>
                      <div class="flex items-center gap-2">
                        <div class="text-base text-gray-300 font-semibold line-clamp-1">
                          <%= show.channel_name %>
                        </div>
                        <div
                          :if={show.channel_twitter_url}
                          target="_blank"
                          rel="noopener noreferrer"
                          href={show.channel_twitter_url}
                        >
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
                            class="text-white"
                          >
                            <path stroke="none" d="M0 0h24v24H0z" fill="none" /><path d="M4 4l11.733 16h4.267l-11.733 -16z" /><path d="M4 20l6.768 -6.768m2.46 -2.46l6.772 -6.772" />
                          </svg>
                        </div>
                      </div>
                    </div>
                    <div
                      :if={show.scheduled_for}
                      class="shrink-0 sm:hidden xl:flex bg-gray-900 px-3 py-2 rounded-lg ring-1 ring-green-300 mr-auto sm:mr-0 sm:ml-auto flex items-center space-x-2"
                    >
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
                        class="h-6 w-6 text-green-300 shrink-0"
                      >
                        <path d="M8 2v4"></path>
                        <path d="M16 2v4"></path>
                        <rect width="18" height="18" x="3" y="4" rx="2"></rect>
                        <path d="M3 10h18"></path>
                      </svg>
                      <div class="shrink-0">
                        <div class="text-sm font-semibold">
                          <%= show.scheduled_for
                          |> Timex.to_datetime("Etc/UTC")
                          |> Timex.Timezone.convert("America/New_York")
                          |> Timex.format!("{WDfull}, {Mshort} {D}") %>
                        </div>
                        <div class="text-sm">
                          <%= show.scheduled_for
                          |> Timex.to_datetime("Etc/UTC")
                          |> Timex.Timezone.convert("America/New_York")
                          |> Timex.format!("{h12}:{m} {am}, Eastern Time") %>
                        </div>
                      </div>
                    </div>
                  </div>

                  <div
                    :if={length(Enum.filter(@show_eps, fn v -> v.show_id == show.id end)) > 0}
                    class="mt-[2rem] -mb-2"
                  >
                    <div class="flex justify-between items-center gap-2 px-2">
                      <h3 class="text-sm uppercase text-gray-300 font-semibold">Past episodes</h3>
                    </div>
                    <div class="p-2 flex gap-4 overflow-x-scroll scrollbar-thin">
                      <div
                        :for={video <- Enum.filter(@show_eps, fn v -> v.show_id == show.id end)}
                        class="max-w-[12rem] sm:max-w-[16rem] shrink-0 w-full"
                      >
                        <div class="truncate" href={~p"/#{video.channel_handle}/#{video.id}"}>
                          <.video_thumbnail video={video} class="rounded-xl" />
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </.link>
          </li>
        </ul>
      </div>

      <div class="pt-12">
        <h2 class="text-white text-3xl font-semibold">
          Most recent livestreams
        </h2>
        <div>
          <div class="pt-4 gap-8 grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3">
            <.video_entry :for={video <- @videos} video={video} />
          </div>
        </div>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    shows = Shows.list_featured_shows()
    show_eps = shows |> Enum.map(fn s -> s.id end) |> Library.list_videos_by_show_ids()
    videos = Library.list_videos(150)

    {:ok,
     socket
     |> assign(:show_eps, show_eps)
     |> assign(:videos, videos)
     |> assign(:shows, shows)}
  end

  def handle_params(params, _url, socket) do
    {:noreply, socket |> apply_action(socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :show, _params) do
    socket |> assign(:page_title, nil)
  end
end
