defmodule AlgoraWeb.HomeLive do
  use AlgoraWeb, :live_view

  alias Algora.{Library, Shows}
  alias AlgoraWeb.HeroComponent

  @impl true
  def render(assigns) do
    ~H"""
    <!--
    This example requires updating your template:

    ```
    <html class="h-full bg-white">
    <body class="h-full">
    ```
    -->
    <div>
      <!-- Off-canvas menu for mobile, show/hide based on off-canvas menu state. -->
      <div class="relative z-50 lg:hidden" role="dialog" aria-modal="true">
        <!--
      Off-canvas menu backdrop, show/hide based on off-canvas menu state.

      Entering: "transition-opacity ease-linear duration-300"
        From: "opacity-0"
        To: "opacity-100"
      Leaving: "transition-opacity ease-linear duration-300"
        From: "opacity-100"
        To: "opacity-0"
    -->
        <div class="fixed inset-0 bg-gray-900/80" aria-hidden="true"></div>

        <div class="fixed inset-0 flex">
          <!--
        Off-canvas menu, show/hide based on off-canvas menu state.

        Entering: "transition ease-in-out duration-300 transform"
          From: "-translate-x-full"
          To: "translate-x-0"
        Leaving: "transition ease-in-out duration-300 transform"
          From: "translate-x-0"
          To: "-translate-x-full"
      -->
          <div class="relative mr-16 flex w-full max-w-xs flex-1">
            <!--
          Close button, show/hide based on off-canvas menu state.

          Entering: "ease-in-out duration-300"
            From: "opacity-0"
            To: "opacity-100"
          Leaving: "ease-in-out duration-300"
            From: "opacity-100"
            To: "opacity-0"
        -->
            <div class="absolute left-full top-0 flex w-16 justify-center pt-5">
              <button type="button" class="-m-2.5 p-2.5">
                <span class="sr-only">Close sidebar</span>
                <svg
                  class="h-6 w-6 text-white"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke-width="1.5"
                  stroke="currentColor"
                  aria-hidden="true"
                >
                  <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
                </svg>
              </button>
            </div>
            <!-- Sidebar component, swap this element with another sidebar if you like -->
            <div class="flex grow flex-col gap-y-5 overflow-y-auto bg-gray-900 px-6 pb-2 ring-1 ring-white/10">
              <div class="flex h-16 shrink-0 items-center">
                <img
                  class="h-8 w-auto"
                  src="https://tailwindui.com/img/logos/mark.svg?color=indigo&shade=500"
                  alt="Your Company"
                />
              </div>
              <nav class="flex flex-1 flex-col">
                <ul role="list" class="flex flex-1 flex-col gap-y-7">
                  <li>
                    <ul role="list" class="-mx-2 space-y-1">
                      <li>
                        <!-- Current: "bg-gray-800 text-white", Default: "text-gray-400 hover:text-white hover:bg-gray-800" -->
                        <a
                          href="#"
                          class="group flex gap-x-3 rounded-md bg-gray-800 p-2 text-sm font-semibold leading-6 text-white"
                        >
                          <svg
                            class="h-6 w-6 shrink-0"
                            fill="none"
                            viewBox="0 0 24 24"
                            stroke-width="1.5"
                            stroke="currentColor"
                            aria-hidden="true"
                          >
                            <path
                              stroke-linecap="round"
                              stroke-linejoin="round"
                              d="M2.25 12l8.954-8.955c.44-.439 1.152-.439 1.591 0L21.75 12M4.5 9.75v10.125c0 .621.504 1.125 1.125 1.125H9.75v-4.875c0-.621.504-1.125 1.125-1.125h2.25c.621 0 1.125.504 1.125 1.125V21h4.125c.621 0 1.125-.504 1.125-1.125V9.75M8.25 21h8.25"
                            />
                          </svg>
                          Dashboard
                        </a>
                      </li>
                      <li>
                        <a
                          href="#"
                          class="group flex gap-x-3 rounded-md p-2 text-sm font-semibold leading-6 text-gray-400 hover:bg-gray-800 hover:text-white"
                        >
                          <svg
                            class="h-6 w-6 shrink-0"
                            fill="none"
                            viewBox="0 0 24 24"
                            stroke-width="1.5"
                            stroke="currentColor"
                            aria-hidden="true"
                          >
                            <path
                              stroke-linecap="round"
                              stroke-linejoin="round"
                              d="M15 19.128a9.38 9.38 0 002.625.372 9.337 9.337 0 004.121-.952 4.125 4.125 0 00-7.533-2.493M15 19.128v-.003c0-1.113-.285-2.16-.786-3.07M15 19.128v.106A12.318 12.318 0 018.624 21c-2.331 0-4.512-.645-6.374-1.766l-.001-.109a6.375 6.375 0 0111.964-3.07M12 6.375a3.375 3.375 0 11-6.75 0 3.375 3.375 0 016.75 0zm8.25 2.25a2.625 2.625 0 11-5.25 0 2.625 2.625 0 015.25 0z"
                            />
                          </svg>
                          Team
                        </a>
                      </li>
                      <li>
                        <a
                          href="#"
                          class="group flex gap-x-3 rounded-md p-2 text-sm font-semibold leading-6 text-gray-400 hover:bg-gray-800 hover:text-white"
                        >
                          <svg
                            class="h-6 w-6 shrink-0"
                            fill="none"
                            viewBox="0 0 24 24"
                            stroke-width="1.5"
                            stroke="currentColor"
                            aria-hidden="true"
                          >
                            <path
                              stroke-linecap="round"
                              stroke-linejoin="round"
                              d="M2.25 12.75V12A2.25 2.25 0 014.5 9.75h15A2.25 2.25 0 0121.75 12v.75m-8.69-6.44l-2.12-2.12a1.5 1.5 0 00-1.061-.44H4.5A2.25 2.25 0 002.25 6v12a2.25 2.25 0 002.25 2.25h15A2.25 2.25 0 0021.75 18V9a2.25 2.25 0 00-2.25-2.25h-5.379a1.5 1.5 0 01-1.06-.44z"
                            />
                          </svg>
                          Projects
                        </a>
                      </li>
                      <li>
                        <a
                          href="#"
                          class="group flex gap-x-3 rounded-md p-2 text-sm font-semibold leading-6 text-gray-400 hover:bg-gray-800 hover:text-white"
                        >
                          <svg
                            class="h-6 w-6 shrink-0"
                            fill="none"
                            viewBox="0 0 24 24"
                            stroke-width="1.5"
                            stroke="currentColor"
                            aria-hidden="true"
                          >
                            <path
                              stroke-linecap="round"
                              stroke-linejoin="round"
                              d="M6.75 3v2.25M17.25 3v2.25M3 18.75V7.5a2.25 2.25 0 012.25-2.25h13.5A2.25 2.25 0 0121 7.5v11.25m-18 0A2.25 2.25 0 005.25 21h13.5A2.25 2.25 0 0021 18.75m-18 0v-7.5A2.25 2.25 0 015.25 9h13.5A2.25 2.25 0 0121 11.25v7.5"
                            />
                          </svg>
                          Calendar
                        </a>
                      </li>
                      <li>
                        <a
                          href="#"
                          class="group flex gap-x-3 rounded-md p-2 text-sm font-semibold leading-6 text-gray-400 hover:bg-gray-800 hover:text-white"
                        >
                          <svg
                            class="h-6 w-6 shrink-0"
                            fill="none"
                            viewBox="0 0 24 24"
                            stroke-width="1.5"
                            stroke="currentColor"
                            aria-hidden="true"
                          >
                            <path
                              stroke-linecap="round"
                              stroke-linejoin="round"
                              d="M15.75 17.25v3.375c0 .621-.504 1.125-1.125 1.125h-9.75a1.125 1.125 0 01-1.125-1.125V7.875c0-.621.504-1.125 1.125-1.125H6.75a9.06 9.06 0 011.5.124m7.5 10.376h3.375c.621 0 1.125-.504 1.125-1.125V11.25c0-4.46-3.243-8.161-7.5-8.876a9.06 9.06 0 00-1.5-.124H9.375c-.621 0-1.125.504-1.125 1.125v3.5m7.5 10.375H9.375a1.125 1.125 0 01-1.125-1.125v-9.25m12 6.625v-1.875a3.375 3.375 0 00-3.375-3.375h-1.5a1.125 1.125 0 01-1.125-1.125v-1.5a3.375 3.375 0 00-3.375-3.375H9.75"
                            />
                          </svg>
                          Documents
                        </a>
                      </li>
                      <li>
                        <a
                          href="#"
                          class="group flex gap-x-3 rounded-md p-2 text-sm font-semibold leading-6 text-gray-400 hover:bg-gray-800 hover:text-white"
                        >
                          <svg
                            class="h-6 w-6 shrink-0"
                            fill="none"
                            viewBox="0 0 24 24"
                            stroke-width="1.5"
                            stroke="currentColor"
                            aria-hidden="true"
                          >
                            <path
                              stroke-linecap="round"
                              stroke-linejoin="round"
                              d="M10.5 6a7.5 7.5 0 107.5 7.5h-7.5V6z"
                            />
                            <path
                              stroke-linecap="round"
                              stroke-linejoin="round"
                              d="M13.5 10.5H21A7.5 7.5 0 0013.5 3v7.5z"
                            />
                          </svg>
                          Reports
                        </a>
                      </li>
                    </ul>
                  </li>
                  <li>
                    <div class="text-xs font-semibold leading-6 text-gray-400">Your teams</div>
                    <ul role="list" class="-mx-2 mt-2 space-y-1">
                      <li>
                        <!-- Current: "bg-gray-800 text-white", Default: "text-gray-400 hover:text-white hover:bg-gray-800" -->
                        <a
                          href="#"
                          class="group flex gap-x-3 rounded-md p-2 text-sm font-semibold leading-6 text-gray-400 hover:bg-gray-800 hover:text-white"
                        >
                          <span class="flex h-6 w-6 shrink-0 items-center justify-center rounded-lg border border-gray-700 bg-gray-800 text-[0.625rem] font-medium text-gray-400 group-hover:text-white">
                            H
                          </span>
                          <span class="truncate">Heroicons</span>
                        </a>
                      </li>
                      <li>
                        <a
                          href="#"
                          class="group flex gap-x-3 rounded-md p-2 text-sm font-semibold leading-6 text-gray-400 hover:bg-gray-800 hover:text-white"
                        >
                          <span class="flex h-6 w-6 shrink-0 items-center justify-center rounded-lg border border-gray-700 bg-gray-800 text-[0.625rem] font-medium text-gray-400 group-hover:text-white">
                            T
                          </span>
                          <span class="truncate">Tailwind Labs</span>
                        </a>
                      </li>
                      <li>
                        <a
                          href="#"
                          class="group flex gap-x-3 rounded-md p-2 text-sm font-semibold leading-6 text-gray-400 hover:bg-gray-800 hover:text-white"
                        >
                          <span class="flex h-6 w-6 shrink-0 items-center justify-center rounded-lg border border-gray-700 bg-gray-800 text-[0.625rem] font-medium text-gray-400 group-hover:text-white">
                            W
                          </span>
                          <span class="truncate">Workcation</span>
                        </a>
                      </li>
                    </ul>
                  </li>
                </ul>
              </nav>
            </div>
          </div>
        </div>
      </div>
      <!-- Static sidebar for desktop -->
      <div class="hidden lg:fixed lg:inset-y-0 lg:z-50 lg:flex lg:w-96 lg:flex-col">
        <!-- Sidebar component, swap this element with another sidebar if you like -->
        <div class="flex grow flex-col gap-y-5 overflow-y-auto bg-gray-950 px-4">
          <div class="flex h-16 shrink-0 items-center">
            <div class="h-8" />
          </div>
          <nav class="flex flex-1 flex-col">
            <ul role="list" class="space-y-2">
              <%= for channel <- @channels do %>
                <li class="relative col-span-1 flex shadow-sm rounded-md overflow-hidden">
                  <.link
                    navigate={channel_path(channel)}
                    class="flex-1 flex items-center justify-between truncate gap-3"
                  >
                    <img
                      class="w-10 h-10 flex-shrink-0 flex items-center justify-center rounded-full bg-purple-300"
                      src={channel.avatar_url}
                      alt={channel.handle}
                    />
                    <div class="flex-1 flex items-center justify-between text-gray-50 text-sm hover:text-gray-300 truncate">
                      <div class="flex-1 py-1 text-sm truncate">
                        <div class="font-semibold truncate"><%= channel.name %></div>
                        <div class="font-medium truncate"><%= channel.tagline %></div>
                      </div>
                    </div>
                    <%= if channel.is_live do %>
                      <div class="flex items-center gap-2">
                        <span class="w-2.5 h-2.5 bg-red-500 rounded-full" aria-hidden="true" />
                        <span class="text-sm font-medium">Live</span>
                      </div>
                    <% else %>
                      <div class="flex items-center gap-2">
                        <span class="text-sm font-medium">Offline</span>
                      </div>
                    <% end %>
                  </.link>
                </li>
              <% end %>
            </ul>
          </nav>
        </div>
      </div>

      <div class="sticky top-0 z-40 flex items-center gap-x-6 bg-gray-900 px-4 py-4 shadow-sm sm:px-6 lg:hidden">
        <button type="button" class="-m-2.5 p-2.5 text-gray-400 lg:hidden">
          <span class="sr-only">Open sidebar</span>
          <svg
            class="h-6 w-6"
            fill="none"
            viewBox="0 0 24 24"
            stroke-width="1.5"
            stroke="currentColor"
            aria-hidden="true"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              d="M3.75 6.75h16.5M3.75 12h16.5m-16.5 5.25h16.5"
            />
          </svg>
        </button>
        <div class="flex-1 text-sm font-semibold leading-6 text-white">Dashboard</div>
        <a href="#">
          <span class="sr-only">Your profile</span>
          <img
            class="h-8 w-8 rounded-full bg-gray-800"
            src="https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=facearea&facepad=2&w=256&h=256&q=80"
            alt=""
          />
        </a>
      </div>

      <main class="lg:pl-96">
        <div class="mx-auto pb-6 space-y-6">
          <div :if={@livestream} class="relative">
            <div class="w-full relative">
              <.live_component module={HeroComponent} id="home-player" />
              <div class="absolute inset-0 bg-gradient-to-r from-gray-950/80 to-transparent to-50%">
              </div>
              <div class="absolute inset-0 bg-gradient-to-b from-gray-950/40 to-transparent to-20%">
              </div>
              <div class="absolute my-auto top-1/2 -translate-y-1/2 left-8 w-1/2 truncate">
                <div class="text-7xl font-bold [text-shadow:#020617_1px_0_10px]">
                  <%= @livestream.channel_name %>
                </div>
                <div class="pt-2 text-xl [text-shadow:#020617_1px_0_10px] font-medium truncate">
                  <%= @livestream.title %>
                </div>
                <.button class="mt-4">
                  <.link href={"/#{@livestream.channel_handle}/#{@livestream.id}"} class="text-lg">
                    Watch now
                  </.link>
                </.button>
              </div>
            </div>
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
                  <.link
                    navigate={~p"/shows/#{show.slug}"}
                    class="absolute h-[10rem] w-full inset-0 z-10"
                  >
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
                          <h3 class="text-sm uppercase text-gray-300 font-semibold">
                            Past episodes
                          </h3>
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
      </main>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    shows = Shows.list_featured_shows()
    show_eps = shows |> Enum.map(fn s -> s.id end) |> Library.list_videos_by_show_ids()
    videos = Library.list_videos(150)
    livestream = Library.list_livestreams(1) |> Enum.at(0)
    active_channels = Library.list_active_channels(limit: 20)

    if connected?(socket) do
      Library.subscribe_to_livestreams()

      if livestream do
        send_update(HeroComponent, %{
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
     |> assign(:livestream, livestream)
     |> assign(:channels, active_channels)}
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
    send_update(HeroComponent, %{
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
