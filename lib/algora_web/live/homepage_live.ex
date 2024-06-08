defmodule AlgoraWeb.HomepageLive do
  use AlgoraWeb, :live_view

  alias Algora.{Library, Shows, Events}

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto pt-2 pb-6 px-4 sm:px-6 space-y-6">
      <.header class="pt-8">
        <h1 class="text-4xl font-semibold">Livestreaming for developers</h1>
        <p class="text-xl font-medium text-gray-200 italic">You'll never ship alone!</p>
      </.header>

      <div :if={length(@livestreams) > 0}>
        <h2 class="text-white text-3xl font-semibold">
          Live now
        </h2>
        <ul class="mt-4 grid grid-cols-3" role="group">
          <li
            :for={livestream <- @livestreams}
            class="relative flex shadow-sm rounded-md overflow-hidden"
          >
            <.link
              navigate={"/#{livestream.channel_handle}/#{livestream.id}"}
              class="pr-3 flex-1 flex items-center justify-between border-t border-r border-b border-gray-700 bg-gray-900 rounded-r-md truncate"
            >
              <img
                class="w-12 h-12 flex-shrink-0 flex items-center justify-center rounded-l-md bg-purple-300"
                src={livestream.channel_avatar_url}
                alt={livestream.channel_handle}
              />
              <div class="flex-1 flex items-center justify-between text-gray-50 text-sm font-medium hover:text-gray-300 pl-3">
                <div class="flex-1 py-1 text-sm truncate">
                  <%= livestream.channel_handle %>
                </div>
              </div>
              <span class="w-2.5 h-2.5 bg-red-500 rounded-full" aria-hidden="true" />
            </.link>
          </li>
        </ul>
      </div>

      <div class="pt-12">
        <h2 class="text-white text-3xl font-semibold">
          Shows
        </h2>
        <ul role="list" class="pt-4 grid grid-cols-1 gap-12 sm:grid-cols-2">
          <li :for={show <- @shows} class="col-span-1">
            <div class="h-full flex flex-col rounded-2xl overflow-hidden bg-[#15112b] ring-1 ring-white/20 text-center shadow-lg relative group">
              <img
                class="object-cover absolute inset-0 shrink-0 h-[12rem] w-full bg-gray-950"
                src={show.image_url}
                alt=""
              />
              <div class="absolute h-[12rem] w-full inset-0 bg-gradient-to-b from-transparent to-[#15112b]" />
              <.link navigate={~p"/shows/#{show.slug}"} class="absolute h-[10rem] w-full inset-0 z-10">
              </.link>
              <div class="relative text-left h-full">
                <div class="flex flex-1 flex-col h-full">
                  <div class="px-4 mt-[8rem] flex-col sm:flex-row flex sm:items-center gap-4">
                    <.link
                      :if={show.channel_handle != "algora"}
                      navigate={~p"/shows/#{show.slug}"}
                      class="shrink-0"
                    >
                      <img
                        class="h-[8rem] w-[8rem] rounded-full ring-4 ring-white shrink-0"
                        src={show.channel_avatar_url}
                        alt=""
                      />
                    </.link>
                    <div :if={show.channel_handle == "algora"} class="h-[8rem] w-0 -ml-4"></div>
                    <div>
                      <.link navigate={~p"/shows/#{show.slug}"}>
                        <h3 class="mt-auto text-3xl font-semibold text-white [text-shadow:#000_10px_5px_10px] line-clamp-2 hover:underline">
                          <%= show.title %>
                        </h3>
                      </.link>
                      <div :if={show.channel_handle != "algora"} class="flex items-center gap-2">
                        <.link navigate={~p"/#{show.channel_handle}"}>
                          <div class="text-base text-gray-300 font-semibold line-clamp-1 hover:underline">
                            <%= show.channel_name %>
                          </div>
                        </.link>
                        <.link
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
                        </.link>
                      </div>
                      <div :if={show.channel_handle == "algora"} class="h-[24px]"></div>
                    </div>
                    <.link
                      :if={show.scheduled_for}
                      navigate={~p"/shows/#{show.slug}"}
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
                    </.link>
                  </div>

                  <div
                    :if={length(Enum.filter(@show_eps, fn v -> v.show_id == show.id end)) > 0}
                    class="mt-auto pt-[2rem] -mb-2"
                  >
                    <div class="flex justify-between items-center gap-2 px-2">
                      <h3 class="text-sm uppercase text-gray-300 font-semibold">Past episodes</h3>
                    </div>
                    <div class="p-2 flex gap-4 overflow-x-scroll scrollbar-thin transition-all">
                      <div
                        :for={video <- Enum.filter(@show_eps, fn v -> v.show_id == show.id end)}
                        class="max-w-[12rem] sm:max-w-[16rem] shrink-0 w-full"
                      >
                        <.link class="truncate" href={~p"/#{video.channel_handle}/#{video.id}"}>
                          <.video_thumbnail video={video} class="rounded-xl" />
                        </.link>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </li>
        </ul>
      </div>

      <div class="pt-12">
        <h2 class="text-white text-3xl font-semibold">
          Most recent livestreams
        </h2>
        <div class="pt-4 gap-8 grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3">
          <.video_entry :for={video <- @videos} video={video} />
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    shows = Shows.list_featured_shows()
    show_eps = shows |> Enum.map(fn s -> s.id end) |> Library.list_videos_by_show_ids()
    videos = Library.list_videos(150)
    livestreams = Library.list_livestreams(10)

    livestream = Enum.at(livestreams, 0)
    if connected?(socket) && livestream, do: send(self(), {:play, livestream})

    {:ok,
     socket
     |> assign(:show_eps, show_eps)
     |> assign(:videos, videos)
     |> assign(:shows, shows)
     |> assign(:livestreams, livestreams)
     |> assign(:video, livestream)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, socket |> apply_action(socket.assigns.live_action, params)}
  end

  @impl true
  def handle_info({:play, video}, socket) do
    schedule_watch_event()

    {:noreply,
     socket
     |> push_event("play_video", %{
       id: video.id,
       url: video.url,
       title: video.title,
       player_type: Library.player_type(video),
       channel_name: video.channel_name
     })}
  end

  def handle_info(:watch_event, socket) do
    Events.log_watched(socket.assigns.current_user, socket.assigns.video)

    # TODO: enable later
    # if socket.assigns.current_user && socket.assigns.video.is_live do
    #   schedule_watch_event(:timer.seconds(2))
    # end

    {:noreply, socket}
  end

  defp schedule_watch_event(ms \\ 0) do
    Process.send_after(self(), :watch_event, ms)
  end

  defp apply_action(socket, :show, _params) do
    socket |> assign(:page_title, nil)
  end
end
