defmodule AlgoraWeb.HomeLive do
  use AlgoraWeb, :live_view

  alias Algora.Library
  alias AlgoraWeb.HeroComponent

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.pwa_install_prompt />
      <!-- Static sidebar for desktop -->
      <div class="hidden lg:fixed lg:inset-y-0 lg:z-50 lg:flex lg:w-[28rem] lg:flex-col">
        <!-- Sidebar component, swap this element with another sidebar if you like -->
        <div class="relative flex grow flex-col gap-y-5 overflow-y-auto scrollbar-thin bg-gray-950 px-4 py-6">
          <nav class="mt-8 flex flex-1 flex-col">
            <ul role="list" class="space-y-3">
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

      <main class="lg:pl-[28rem] relative">
        <div id="navbar" phx-hook="NavBar" class="h-[56px] fixed z-[100] top-0 left-0 right-0 w-full">
          <div class="flex justify-between items-center my-auto h-full">
            <div class="flex items-center h-full w-[28rem] bg-gray-950">
              <.logo class="pl-4 mt-1 w-24 h-auto" />
            </div>
            <div class="pr-4 h-full items-center justify-end gap-2 flex">
              <a
                class="group outline-none w-fit"
                target="_blank"
                rel="noopener"
                href="https://www.youtube.com/@algora-io"
              >
                <div class="text-center font-sans justify-center items-center shrink-0 transition duration-150 select-none group-focus:outline-none group-disabled:opacity-75 group-disabled:pointer-events-none bg-transparent hover:bg-slate-850 disabled:opacity-50 h-8 px-2 text-sm font-semibold rounded-[3px] whitespace-nowrap flex">
                  <div class="justify-center flex w-full items-center gap-x-1">
                    <svg
                      xmlns="http://www.w3.org/2000/svg"
                      width="24"
                      height="24"
                      viewBox="0 0 24 24"
                      fill="currentColor"
                      class="h-5 text-gray-300 transition mr-0.5 shrink-0 justify-start"
                    >
                      <path stroke="none" d="M0 0h24v24H0z" fill="none" /><path d="M18 3a5 5 0 0 1 5 5v8a5 5 0 0 1 -5 5h-12a5 5 0 0 1 -5 -5v-8a5 5 0 0 1 5 -5zm-9 6v6a1 1 0 0 0 1.514 .857l5 -3a1 1 0 0 0 0 -1.714l-5 -3a1 1 0 0 0 -1.514 .857z" />
                    </svg>
                  </div>
                </div>
              </a>
              <a class="group outline-none w-fit" target="_blank" href="https://algora.io/discord">
                <div class="text-center font-sans justify-center items-center shrink-0 transition duration-150 select-none group-focus:outline-none group-disabled:opacity-75 group-disabled:pointer-events-none bg-transparent hover:bg-slate-850 disabled:opacity-50 h-8 px-2 text-sm font-semibold rounded-[3px] whitespace-nowrap flex">
                  <div class="justify-center flex w-full items-center gap-x-1">
                    <svg
                      class="h-7 w-7"
                      width="24"
                      height="24"
                      viewBox="0 0 24 24"
                      xmlns="http://www.w3.org/2000/svg"
                    >
                      <path
                        d="M18.0881 7.3374C18.0116 7.27279 17.9402 7.2032 17.8637 7.14356C17.554 6.88097 17.2269 6.63856 16.8846 6.41792C16.4342 6.13677 15.9516 5.90824 15.4464 5.73702C15.0844 5.61277 14.7172 5.51835 14.35 5.40901C14.2837 5.40901 14.2786 5.38414 14.3092 5.3245C14.3398 5.26485 14.4061 5.14558 14.4469 5.05115C14.4538 5.03366 14.4667 5.0191 14.4835 5.01001C14.5003 5.00092 14.5198 4.99789 14.5387 5.00146C14.809 5.04619 15.0844 5.07601 15.3547 5.13069C15.8281 5.229 16.2896 5.3756 16.7316 5.56805C17.1998 5.76225 17.6502 5.99501 18.0779 6.26385C18.2267 6.353 18.3697 6.45094 18.5063 6.5571C18.5891 6.62989 18.6566 6.71764 18.7051 6.81552C19.1108 7.51363 19.4521 8.24546 19.7251 9.00236C20.1066 10.0234 20.3983 11.0742 20.5971 12.1435C20.7042 12.715 20.7909 13.2866 20.8674 13.8631C20.9184 14.216 20.9388 14.5788 20.9745 14.9366C20.9745 15.0559 20.9745 15.1702 21 15.2895C21 15.3164 20.9911 15.3425 20.9745 15.3641C20.462 15.9257 19.8549 16.398 19.1794 16.7606C18.5379 17.1017 17.8516 17.3558 17.1395 17.5161C16.7511 17.6096 16.3554 17.6711 15.9564 17.7H15.7116C15.701 17.7002 15.6904 17.6981 15.6807 17.6938C15.671 17.6895 15.6624 17.6831 15.6555 17.6752C15.4413 17.4068 15.2323 17.1334 15.0232 16.8551V16.8253C16.3606 16.3823 17.5548 15.6041 18.4859 14.5689C18.3788 14.6434 18.2819 14.718 18.1748 14.7826C17.8739 14.9665 17.5781 15.1504 17.267 15.3193C16.7354 15.61 16.1728 15.8433 15.5892 16.0151C14.6422 16.3069 13.6595 16.474 12.6671 16.5121H12.3713H11.8155C11.4011 16.5146 10.9871 16.4897 10.5762 16.4376C10.1887 16.3879 9.80109 16.3332 9.41351 16.2636C8.86661 16.1567 8.33068 16.002 7.81221 15.8014C7.15233 15.5479 6.523 15.2246 5.93553 14.8372L5.55306 14.5788C6.01711 15.0934 6.54864 15.5462 7.13396 15.9257C7.72153 16.3044 8.35541 16.6099 9.02084 16.8352L8.98514 16.8899L8.39358 17.6553C8.38145 17.6729 8.36453 17.6868 8.34472 17.6956C8.3249 17.7044 8.30298 17.7076 8.28138 17.705C7.93875 17.691 7.59775 17.6511 7.26145 17.5857C6.76756 17.4952 6.28289 17.3621 5.81314 17.1881C5.27458 16.9934 4.76114 16.7382 4.28323 16.4277C3.86783 16.1551 3.48621 15.8365 3.14601 15.4784C3.14601 15.4784 3.12051 15.4386 3.10011 15.4287C3.06012 15.3983 3.03012 15.3571 3.01381 15.3103C2.9975 15.2635 2.99559 15.2131 3.00831 15.1653L3.05421 14.6335C3.0899 14.2856 3.1205 13.9426 3.1664 13.5947C3.2123 13.2468 3.28879 12.7647 3.36529 12.3472C3.51174 11.5311 3.7093 10.7244 3.95685 9.93177C4.16738 9.2543 4.42116 8.59033 4.71671 7.94373C4.91624 7.50667 5.14275 7.08178 5.39497 6.6714C5.46939 6.5728 5.56514 6.49137 5.67544 6.43284C6.1388 6.11857 6.63239 5.84893 7.14925 5.62769C7.71444 5.38251 8.30641 5.20075 8.91375 5.08594L9.47981 5.00643C9.49599 5.00328 9.51279 5.00611 9.52694 5.01438C9.54108 5.02265 9.55155 5.03575 9.55631 5.05115L9.7042 5.33942C9.7297 5.38415 9.7042 5.39907 9.6685 5.40901C9.41351 5.47859 9.15854 5.54319 8.90865 5.61774C8.45618 5.75584 8.01886 5.93729 7.60313 6.15946C7.24627 6.34465 6.9052 6.5574 6.58319 6.79565C6.3588 6.9696 6.14462 7.14853 5.92533 7.32745C5.9235 7.33135 5.92255 7.33557 5.92255 7.33986C5.92255 7.34415 5.9235 7.3484 5.92533 7.35229L5.99163 7.32248C6.471 7.09882 6.95037 6.86522 7.43994 6.65647C8.00719 6.4106 8.59831 6.22081 9.20443 6.08991C9.61682 5.99062 10.0361 5.92083 10.459 5.88114C10.8414 5.84635 11.2239 5.82649 11.6013 5.80661C11.79 5.80661 11.9787 5.80661 12.1673 5.80661C12.5141 5.80661 12.866 5.8414 13.2128 5.86625C13.8437 5.91322 14.4686 6.01806 15.0793 6.17936C15.6332 6.32264 16.1739 6.51049 16.6959 6.74099L17.9606 7.33243L18.0218 7.36224L18.0881 7.3374ZM9.35232 10.5679C9.08643 10.5761 8.82881 10.66 8.6113 10.8093C8.39378 10.9586 8.2259 11.1667 8.12839 11.4079C7.98657 11.7022 7.93351 12.0296 7.97541 12.3522C8.01397 12.7406 8.19505 13.1024 8.48538 13.371C8.61754 13.5006 8.77761 13.6 8.95401 13.6619C9.13041 13.7238 9.31872 13.7467 9.50531 13.7289C9.68475 13.7178 9.85988 13.6705 10.0196 13.5901C10.1794 13.5097 10.3203 13.3979 10.4335 13.2617C10.7252 12.9245 10.8682 12.4886 10.8312 12.049C10.8196 11.7253 10.7096 11.4122 10.515 11.1494C10.3862 10.9659 10.2123 10.8166 10.0093 10.7151C9.80628 10.6135 9.58046 10.563 9.35232 10.5679ZM16.1094 12.1733C16.1148 11.8593 16.0319 11.55 15.8697 11.2787C15.7548 11.0583 15.5775 10.8747 15.3587 10.7496C15.14 10.6245 14.889 10.5632 14.6356 10.5729C14.451 10.578 14.2698 10.6219 14.1043 10.7017C13.9388 10.7815 13.793 10.8953 13.6769 11.0351C13.5285 11.203 13.4159 11.398 13.3459 11.6088C13.2758 11.8196 13.2496 12.0419 13.2689 12.2627C13.2861 12.6947 13.4787 13.1023 13.8043 13.3959C13.9417 13.5243 14.1072 13.6205 14.2883 13.6773C14.4694 13.7342 14.6614 13.7501 14.8498 13.7239C15.1962 13.6764 15.5095 13.4978 15.7218 13.2269C15.9694 12.9284 16.106 12.5571 16.1094 12.1733Z"
                        fill="#CBD5E1"
                      >
                      </path>
                    </svg>
                  </div>
                </div>
              </a>
              <a
                :if={Algora.Stargazer.count()}
                class="group outline-none w-fit"
                target="_blank"
                rel="noopener"
                href="https://github.com/algora-io/tv"
              >
                <div class="text-center font-sans justify-center items-center shrink-0 transition duration-150 select-none group-focus:outline-none group-disabled:opacity-75 group-disabled:pointer-events-none bg-transparent hover:bg-slate-850 disabled:opacity-50 h-8 text-sm font-semibold rounded-[3px] whitespace-nowrap p-2 flex">
                  <div class="justify-center flex w-full items-center gap-x-1">
                    <svg
                      class="h-5 text-gray-300 transition mr-0.5 shrink-0 justify-start"
                      viewBox="0 0 24 24"
                      fill="currentColor"
                      xmlns="http://www.w3.org/2000/svg"
                    >
                      <g clip-path="url(#clip0_571_3822)">
                        <path
                          fill-rule="evenodd"
                          clip-rule="evenodd"
                          d="M12 0C5.37017 0 0 5.50708 0 12.306C0 17.745 3.44015 22.3532 8.20626 23.9849C8.80295 24.0982 9.02394 23.7205 9.02394 23.3881C9.02394 23.0935 9.01657 22.3229 9.00921 21.2956C5.67219 22.0359 4.96501 19.6487 4.96501 19.6487C4.41989 18.2285 3.63168 17.8508 3.63168 17.8508C2.54144 17.0878 3.71271 17.1029 3.71271 17.1029C4.91344 17.1936 5.55433 18.372 5.55433 18.372C6.62247 20.2531 8.36096 19.7092 9.04604 19.3919C9.15654 18.5987 9.46593 18.0548 9.80479 17.745C7.13812 17.4353 4.33886 16.3777 4.33886 11.6638C4.33886 10.3192 4.80295 9.2238 5.57643 8.36261C5.4512 8.05288 5.03867 6.79887 5.69429 5.1067C5.69429 5.1067 6.7035 4.77432 8.99447 6.36827C9.95212 6.09632 10.9761 5.96034 12 5.95279C13.0166 5.95279 14.0479 6.09632 15.0055 6.36827C17.2965 4.77432 18.3057 5.1067 18.3057 5.1067C18.9613 6.79887 18.5488 8.05288 18.4236 8.36261C19.1897 9.2238 19.6538 10.3192 19.6538 11.6638C19.6538 16.3928 16.8471 17.4278 14.1731 17.7375C14.6004 18.1152 14.9908 18.8706 14.9908 20.0189C14.9908 21.6657 14.9761 22.9877 14.9761 23.3957C14.9761 23.728 15.1897 24.1058 15.8011 23.9849C20.5672 22.3532 24 17.745 24 12.3135C24 5.50708 18.6298 0 12 0Z"
                          fill="currentColor"
                        >
                        </path>
                      </g>
                      <defs>
                        <clipPath id="clip0_571_3822">
                          <rect width="24" height="24" fill="currentColor"></rect>
                        </clipPath>
                      </defs>
                    </svg>
                    <span class="hidden xl:block">Star</span>
                    <span class="font-semibold text-gray-300"><%= Algora.Stargazer.count() %></span>
                  </div>
                </div>
              </a>
              <.link
                class="px-4 py-2 sm:flex hidden whitespace-nowrap"
                target="_blank"
                href="/docs/streaming/quickstart"
              >
                <span class="relative font-semibold text-sm">How to livestream</span>
              </.link>
              <%= if @current_user do %>
                <div class="shrink-0">
                  <.simple_dropdown id="navbar-account-dropdown">
                    <:img src={@current_user.avatar_url} alt={@current_user.handle} />
                    <:link navigate={channel_path(@current_user)}>Channel</:link>
                    <:link navigate={~p"/channel/studio"}>Studio</:link>
                    <:link navigate={~p"/subscriptions"}>Subscriptions</:link>
                    <:link navigate={~p"/channel/settings"}>Settings</:link>
                    <:link href={~p"/auth/logout"} method={:delete}>Sign out</:link>
                  </.simple_dropdown>
                </div>
              <% else %>
                <.link
                  navigate="/auth/login"
                  class="rounded-lg bg-gray-50 hover:bg-gray-200 py-1 px-2 text-sm font-semibold leading-6 text-gray-950 active:text-gray-950/80"
                >
                  <span class="relative font-semibold text-sm">Login</span>
                </.link>
              <% end %>
            </div>
          </div>
        </div>

        <div class="mx-auto pb-6">
          <.link
            :if={@hero_video}
            href={~p"/#{@hero_video.channel_handle}/#{@hero_video.id}"}
            class="flex h-full min-h-[100svh] sm:min-h-0"
          >
            <div class="w-full my-auto relative">
              <.live_component module={HeroComponent} id="home-player" />
              <div class="absolute inset-0 bg-gradient-to-r from-gray-950/80 to-transparent to-50%">
              </div>
              <div class="hidden sm:block absolute inset-0 bg-gradient-to-b from-gray-950 to-transparent to-30%">
              </div>
              <div class="absolute my-auto top-1/2 -translate-y-1/2 left-8 w-1/2">
                <div
                  :if={@hero_video.is_live}
                  class="pl-2 mb-2 text-white bg-red-500 rounded-xl font-semibold inline-flex items-center py-0.5"
                >
                  LIVE
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    viewBox="0 0 24 24"
                    fill="currentColor"
                    class="h-6 w-6"
                  >
                    <path stroke="none" d="M0 0h24v24H0z" fill="none" /><path d="M12 7a5 5 0 1 1 -4.995 5.217l-.005 -.217l.005 -.217a5 5 0 0 1 4.995 -4.783z" />
                  </svg>
                </div>
                <div class="text-4xl sm:text-7xl font-bold [text-shadow:#020617_1px_0_10px]">
                  <%= @hero_video.channel_name %>
                </div>
                <div class="pt-2 text-lg sm:text-xl [text-shadow:#020617_1px_0_10px] font-medium">
                  <%= @hero_video.title %>
                </div>
              </div>
            </div>
          </.link>

          <div class="pt-8 px-4 lg:pl-0 lg:pr-8 gap-8 grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3">
            <.video_entry :for={video <- @most_recent_videos} video={video} />
          </div>

          <div class="px-4 lg:pl-0 lg:pr-8 pt-12">
            <h2 class="text-white text-3xl font-semibold">
              Shows
            </h2>
            <ul role="list" class="pt-4 grid grid-cols-2 gap-4 md:grid-cols-4">
              <%= for show <- @shows do %>
                <li class="col-span-1 rounded-lg overflow-hidden">
                  <div>
                    <.link
                      navigate={~p"/shows/#{show.slug}"}
                      class="aspect-h-1 aspect-w-1 w-full overflow-hidden bg-gray-200 group-hover:opacity-75"
                    >
                      <img src={show.poster} alt={show.slug} class="h-full w-full" />
                    </.link>
                    <.link
                      navigate={~p"/#{show.channel_handle}"}
                      class="bg-gray-900 p-2 flex justify-between"
                    >
                      <div class="flex-1 flex items-center justify-between truncate gap-3">
                        <img
                          class="w-10 h-10 flex-shrink-0 flex items-center justify-center rounded-full bg-purple-300"
                          src={show.channel_avatar_url}
                          alt={show.channel_name}
                        />
                        <div class="flex-1 flex items-center justify-between text-gray-50 text-sm hover:text-gray-300">
                          <div class="flex-1 py-1 text-sm">
                            <div class="font-semibold whitespace-normal">
                              <%= show.channel_name %>
                            </div>
                          </div>
                        </div>
                      </div>
                    </.link>
                  </div>
                </li>
              <% end %>
            </ul>
          </div>

          <div class="px-4 lg:pl-0 lg:pr-8 pt-12">
            <h2 class="text-white text-3xl font-semibold">
              Past livestreams
            </h2>
            <div class="pt-4 gap-8 grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3">
              <.video_entry :for={video <- @rest_of_videos} video={video} />
            </div>
          </div>
        </div>
      </main>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    active_channels = Library.list_active_channels(limit: 20)
    videos = Library.list_videos(150)

    [hero_video | recent_videos] = videos
    {most_recent_videos, rest_of_videos} = Enum.split(recent_videos, 3)

    shows = [
      %{
        slug: "tsperf",
        poster: ~p"/images/shows/coding-challenges.jpg",
        channel_name: "Algora",
        channel_handle: "algora",
        channel_avatar_url: "https://avatars.githubusercontent.com/u/136125894?v=4"
      },
      %{
        slug: "coss",
        poster: ~p"/images/shows/coss-office-hours.jpg",
        channel_name: "Peer Richelsen",
        channel_handle: "PeerRich",
        channel_avatar_url: "https://avatars.githubusercontent.com/u/8019099?v=4"
      },
      %{
        slug: "the_savefile",
        poster: ~p"/images/shows/the-save-file.jpg",
        channel_name: "Glauber Costa",
        channel_handle: "glommer",
        channel_avatar_url: "https://avatars.githubusercontent.com/u/331197?v=4"
      },
      %{
        slug: "rfc",
        poster: ~p"/images/shows/request-for-comments.jpg",
        channel_name: "Andreas Klinger",
        channel_handle: "rfc",
        channel_avatar_url: "https://avatars.githubusercontent.com/u/245833?v=4"
      },
      %{
        slug: "coss-founder-podcast",
        poster: ~p"/images/shows/coss-founder-podcast.jpg",
        channel_name: "Ioannis R. Florokapis",
        channel_handle: "algora",
        channel_avatar_url: "https://avatars.githubusercontent.com/u/118012453?v=4"
      },
      %{
        slug: "bounties",
        poster: ~p"/images/shows/live-bounty-hunting.jpg",
        channel_name: "Algora",
        channel_handle: "algora",
        channel_avatar_url: "https://avatars.githubusercontent.com/u/136125894?v=4"
      },
      %{
        slug: "eu-acc",
        poster: ~p"/images/shows/eu-acc.jpg",
        channel_name: "Andreas Klinger",
        channel_handle: "rfc",
        channel_avatar_url: "https://avatars.githubusercontent.com/u/245833?v=4"
      },
      %{
        slug: "buildinpublic",
        poster: ~p"/images/shows/build-in-public.jpg",
        channel_name: "Algora",
        channel_handle: "algora",
        channel_avatar_url: "https://avatars.githubusercontent.com/u/136125894?v=4"
      }
    ]

    if connected?(socket) do
      Library.subscribe_to_livestreams()

      if hero_video do
        send_update(HeroComponent, %{
          id: "home-player",
          video: hero_video,
          current_user: socket.assigns.current_user
        })
      end
    end

    {:ok,
     socket
     |> assign(:most_recent_videos, most_recent_videos)
     |> assign(:rest_of_videos, rest_of_videos)
     |> assign(:shows, shows)
     |> assign(:hero_video, hero_video)
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
