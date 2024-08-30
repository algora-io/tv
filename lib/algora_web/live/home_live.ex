defmodule AlgoraWeb.HomeLive do
  use AlgoraWeb, :live_view

  alias Algora.{Library, Shows}
  alias AlgoraWeb.PlayerComponent

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto pt-2 pb-6 px-4 sm:px-6 space-y-6">
      <div class="-mt-12">
        <div class="mx-auto">
          <div class="mx-auto mt-16 max-w-2xl rounded-3xl bg-white/5 ring-2 ring-purple-500 sm:mt-20 lg:mx-0 lg:flex lg:max-w-none lg:items-center">
            <div class="p-8 sm:p-10 lg:flex-auto">
              <h3 class="text-3xl font-bold tracking-tight text-white">
                ✨ New feature: Live Billboards!
              </h3>
              <p class="mt-6 font-medium text-lg leading-7 text-gray-300">
                We just launched in-video ads to help developers earn money while livestreaming and give devtools companies a channel to reach new audiences.
              </p>
              <div class="mt-6 flex items-center gap-4">
                <.button>
                  <.link navigate={~p"/partner"}>
                    Learn more
                  </.link>
                </.button>
                <.button>
                  <.link
                    href="https://www.youtube.com/watch?v=te6k6EfHjnI"
                    target="_blank"
                    rel="noopener noreferrer"
                  >
                    Watch demo
                  </.link>
                </.button>
              </div>
            </div>
            <div class="-mt-2 p-8 pt-0 sm:p-10 sm:pt-0 lg:p-2 lg:mr-2 xl:mr-0 lg:mt-0 lg:w-full lg:max-w-lg xl:max-w-xl lg:flex-shrink-0 h-full">
              <.link
                class="cursor-pointer truncate"
                href="https://www.youtube.com/watch?v=te6k6EfHjnI"
                rel="noopener noreferrer"
                target="_blank"
              >
                <div class="relative flex items-center justify-center overflow-hidden aspect-[16/9] bg-gray-800 rounded-sm lg:rounded-3xl lg:rounded-l-none">
                  <img
                    src={~p"/images/live-billboard.png"}
                    alt="Algora Live Billboards"
                    class="absolute w-full h-full object-cover z-10"
                  />
                  <div class="absolute font-medium text-xs px-2 py-0.5 rounded-xl bottom-1 bg-gray-950/90 text-white right-1 z-20">
                    2:27
                  </div>
                </div>
              </.link>
            </div>
          </div>
        </div>
      </div>

      <.header class="pt-8">
        <h1 class="text-4xl font-semibold">Livestreaming for developers</h1>
        <p class="text-xl font-medium text-gray-200 italic">You'll never ship alone!</p>
      </.header>

      <div :if={@livestream} class="flex flex-col sm:flex-row items-center justify-center gap-4">
        <div class="w-full max-w-3xl">
          <.live_component module={PlayerComponent} id="home-player" />
        </div>
        <.link
          href={"/#{@livestream.channel_handle}/#{@livestream.id}"}
          class="w-full max-w-sm p-6 bg-gray-800/40 hover:bg-gray-800/60 overflow-hidden rounded-lg lg:rounded-2xl shadow-inner shadow-white/[10%] lg:border border-white/[15%] hover:border/white/[20%]"
        >
          <div class="flex items-center gap-4">
            <div class="relative h-20 w-20 shrink-0">
              <img
                src={@livestream.channel_avatar_url}
                alt={@livestream.channel_handle}
                class="w-full h-full p-1 ring-4 rounded-full ring-red-500"
              />
              <div class="absolute bottom-0 translate-y-1/2 ring-[3px] ring-gray-800 left-1/2 -translate-x-1/2 rounded px-1 font-medium mx-auto bg-red-500 text-xs">
                LIVE
              </div>
            </div>
            <div>
              <div class="text-3xl font-semibold"><%= @livestream.channel_name %></div>
              <div class="font-medium text-gray-300">@<%= @livestream.channel_handle %></div>
            </div>
          </div>
          <div class="pt-4 font-medium text-gray-100"><%= @livestream.title %></div>
        </.link>
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
    livestream = Library.list_livestreams(1) |> Enum.at(0)

    if connected?(socket) do
      Library.subscribe_to_livestreams()

      if livestream do
        send_update(PlayerComponent, %{
          id: "home-player",
          video: livestream,
          current_user: socket.assigns.current_user
        })
      end
    end

    {:ok,
     socket
     |> assign(:show_eps, show_eps)
     |> assign(:videos, videos)
     |> assign(:shows, shows)
     |> assign(:livestream, livestream)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, socket |> apply_action(socket.assigns.live_action, params)}
  end

  @impl true
  def handle_info(
        {Library, %Library.Events.LivestreamStarted{video: %{visibility: :public} = video}},
        %{assigns: %{livestream: nil}} = socket
      ) do
    send_update(PlayerComponent, %{
      id: "home-player",
      video: video,
      current_user: socket.assigns.current_user
    })

    {:noreply, socket |> assign(:livestream, video)}
  end

  def handle_info(_arg, socket) do
    {:noreply, socket}
  end

  defp apply_action(socket, :show, _params) do
    socket |> assign(:page_title, nil)
  end
end
