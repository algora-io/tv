defmodule AlgoraWeb.VideoLive do
  use AlgoraWeb, :live_view
  require Logger

  alias Algora.{Accounts, Library, Storage, Chat}
  alias AlgoraWeb.{LayoutComponent, Presence}
  alias AlgoraWeb.ChannelLive.{StreamFormComponent}

  @impl true
  def render(assigns) do
    ~H"""
    <div class="lg:mr-[24rem] h-[calc(100svh-56.25vw-64px)] lg:h-auto">
      <div class="lg:border-b lg:border-gray-700 py-4">
        <figure class="relative isolate -mt-4 pt-4 pb-4">
          <svg
            viewBox="0 0 162 128"
            fill="none"
            aria-hidden="true"
            class="absolute left-0 top-0 -z-10 h-12 stroke-white/75 px-4"
          >
            <path
              id="b56e9dab-6ccb-4d32-ad02-6b4bb5d9bbeb"
              d="M65.5697 118.507L65.8918 118.89C68.9503 116.314 71.367 113.253 73.1386 109.71C74.9162 106.155 75.8027 102.28 75.8027 98.0919C75.8027 94.237 75.16 90.6155 73.8708 87.2314C72.5851 83.8565 70.8137 80.9533 68.553 78.5292C66.4529 76.1079 63.9476 74.2482 61.0407 72.9536C58.2795 71.4949 55.276 70.767 52.0386 70.767C48.9935 70.767 46.4686 71.1668 44.4872 71.9924L44.4799 71.9955L44.4726 71.9988C42.7101 72.7999 41.1035 73.6831 39.6544 74.6492C38.2407 75.5916 36.8279 76.455 35.4159 77.2394L35.4047 77.2457L35.3938 77.2525C34.2318 77.9787 32.6713 78.3634 30.6736 78.3634C29.0405 78.3634 27.5131 77.2868 26.1274 74.8257C24.7483 72.2185 24.0519 69.2166 24.0519 65.8071C24.0519 60.0311 25.3782 54.4081 28.0373 48.9335C30.703 43.4454 34.3114 38.345 38.8667 33.6325C43.5812 28.761 49.0045 24.5159 55.1389 20.8979C60.1667 18.0071 65.4966 15.6179 71.1291 13.7305C73.8626 12.8145 75.8027 10.2968 75.8027 7.38572C75.8027 3.6497 72.6341 0.62247 68.8814 1.1527C61.1635 2.2432 53.7398 4.41426 46.6119 7.66522C37.5369 11.6459 29.5729 17.0612 22.7236 23.9105C16.0322 30.6019 10.618 38.4859 6.47981 47.558L6.47976 47.558L6.47682 47.5647C2.4901 56.6544 0.5 66.6148 0.5 77.4391C0.5 84.2996 1.61702 90.7679 3.85425 96.8404L3.8558 96.8445C6.08991 102.749 9.12394 108.02 12.959 112.654L12.959 112.654L12.9646 112.661C16.8027 117.138 21.2829 120.739 26.4034 123.459L26.4033 123.459L26.4144 123.465C31.5505 126.033 37.0873 127.316 43.0178 127.316C47.5035 127.316 51.6783 126.595 55.5376 125.148L55.5376 125.148L55.5477 125.144C59.5516 123.542 63.0052 121.456 65.9019 118.881L65.5697 118.507Z"
            >
            </path>
            <use href="#b56e9dab-6ccb-4d32-ad02-6b4bb5d9bbeb" x="86"></use>
          </svg>
          <blockquote class={[
            "text-xl px-4 font-semibold leading-8 text-white sm:text-2xl sm:leading-9 line-clamp-2 min-h-[64px] sm:min-h-none",
            if(@channel.solving_challenge, do: "hidden sm:block")
          ]}>
            <p><%= @video.title %></p>
          </blockquote>
          <div
            :if={@channel.solving_challenge}
            class="-mt-4 block sm:hidden bg-gray-950 text-center py-4"
          >
            <div class="font-medium text-base">
              <.link
                href="https://console.algora.io/challenges/tsperf"
                class="font-semibold text-green-300 hover:underline"
              >
                Solving the $15,000 TSPerf Challenge
              </.link>
            </div>
            <div class="pt-1.5 font-medium text-sm">
              sponsored by
            </div>
            <div class="pt-2.5 mx-auto grid max-w-6xl gap-4 text-center grid-cols-3">
              <a
                target="_blank"
                rel="noopener"
                class="flex h-full flex-1 flex-col items-center text-white no-underline hover:no-underline"
                href="https://unkey.com"
              >
                <img
                  src="https://console.algora.io/banners/unkey.png"
                  alt="Unkey"
                  class="-mt-1 h-8 w-auto saturate-0"
                />
              </a>
              <a
                target="_blank"
                rel="noopener"
                class="flex h-full flex-1 flex-col items-center text-white no-underline hover:no-underline"
                href="https://scalar.com"
              >
                <img
                  src="https://console.algora.io/banners/scalar.png"
                  alt="Scalar"
                  class="h-6 w-auto saturate-0"
                />
              </a>
              <a
                target="_blank"
                rel="noopener"
                class="flex h-full flex-1 flex-col items-center text-white no-underline hover:no-underline"
                href="https://tigrisdata.com"
              >
                <img
                  src="https://assets-global.website-files.com/657988158c7fb30f4d9ef37b/657990b61fd3a5d674cf2298_tigris-logo.svg"
                  alt="Tigris"
                  class="mt-1 h-6 w-auto saturate-0"
                />
              </a>
            </div>
          </div>
        </figure>

        <div class="flex flex-col items-start px-4 justify-start md:flex-row md:items-center md:justify-between gap-8">
          <.link navigate={~p"/#{@channel.handle}"} class="flex items-center gap-4">
            <div class="relative h-20 w-20 shrink-0">
              <img
                src={@channel.avatar_url}
                alt={@channel.handle}
                class={[
                  "w-full h-full p-1 ring-4 rounded-full",
                  if(@channel.is_live, do: "ring-red-500", else: "ring-transparent")
                ]}
              />
              <div
                :if={@channel.is_live}
                class="absolute bottom-0 translate-y-1/2 ring-[3px] ring-gray-800 left-1/2 -translate-x-1/2 rounded px-1 font-medium mx-auto bg-red-500 text-xs"
              >
                LIVE
              </div>
            </div>
            <div>
              <div class="text-2xl font-semibold">
                <%= @channel.name %>
              </div>
              <div
                :if={@channel.tech}
                class="mt-2 relative flex flex-col overflow-hidden max-w-[256px]"
              >
                <div class="relative flex h-1.5 w-full items-center">
                  <div class="flex h-full flex-1 items-center gap-2 overflow-hidden">
                    <div
                      :for={lang <- @channel.tech}
                      class="h-full rounded-full"
                      style={"width:#{lang.pct}%;background-color:#{lang.color}"}
                    >
                    </div>
                  </div>
                </div>
                <ol class="relative mt-0.5 items-start overflow-hidden text-xs">
                  <div tabindex="0" class="-ml-2 flex h-full flex-wrap">
                    <li
                      :for={lang <- @channel.tech}
                      class="group inline-flex cursor-default items-center truncate whitespace-nowrap px-2 py-0.5 transition"
                    >
                      <svg
                        class="mr-1.5 h-2 w-2 flex-none opacity-100"
                        fill={lang.color}
                        viewBox="0 0 8 8"
                      >
                        <circle cx="4" cy="4" r="4"></circle>
                      </svg>
                      <p class="truncate whitespace-nowrap font-medium text-sm"><%= lang.name %></p>
                    </li>
                  </div>
                </ol>
              </div>
              <div :if={!@channel.tech} class="text-sm text-gray-300">@<%= @channel.handle %></div>
            </div>
          </.link>
          <div class="hidden lg:flex gap-6">
            <div>
              <div class="text-xs font-medium text-gray-300 sm:text-sm">
                Watching now
              </div>
              <div class="flex items-center gap-1.5">
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
                >
                  <path stroke="none" d="M0 0h24v24H0z" fill="none" /><path d="M8 7a4 4 0 1 0 8 0a4 4 0 0 0 -8 0" /><path d="M6 21v-2a4 4 0 0 1 4 -4h4a4 4 0 0 1 4 4v2" />
                </svg>
                <div class="font-display text-2xl font-semibold md:text-3xl">
                  <div id="viewer-count" phx-update="stream">
                    <div
                      :for={{dom_id, %{id: id, metas: metas}} <- @streams.presences}
                      :if={id == @channel.handle}
                      id={dom_id}
                    >
                      <%= metas
                      |> Enum.filter(fn meta -> meta.id != @channel.handle end)
                      |> length() %>
                    </div>
                  </div>
                </div>
              </div>
            </div>
            <div :if={@channel.bounties_count}>
              <div class="text-xs font-medium text-gray-300 sm:text-sm">
                Bounties collected
              </div>
              <div class="flex items-center gap-1.5">
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
                >
                  <path stroke="none" d="M0 0h24v24H0z" fill="none" /><path d="M6 5h12l3 5l-8.5 9.5a.7 .7 0 0 1 -1 0l-8.5 -9.5l3 -5" /><path d="M10 12l-2 -2.2l.6 -1" />
                </svg>
                <div class="font-display text-2xl font-semibold md:text-3xl">
                  <%= @channel.bounties_count %>
                </div>
              </div>
            </div>
            <div :if={length(@channel.orgs_contributed) > 0}>
              <div class="text-xs font-medium text-gray-300 sm:text-sm">
                OSS projects contributed
              </div>
              <div class="mt-2 line-clamp-1 space-x-2">
                <a
                  :for={project <- @channel.orgs_contributed}
                  href={"https://console.algora.io/org/#{project.handle}"}
                  class="inline-flex items-center gap-2"
                >
                  <span class="relative shrink-0 overflow-hidden flex h-6 w-6 items-center justify-center rounded-lg sm:h-8 sm:w-8">
                    <img
                      class="aspect-square h-full w-full"
                      alt={project.handle}
                      src={project.avatar_url}
                    />
                  </span>
                </a>
              </div>
            </div>
          </div>
        </div>
      </div>

      <aside
        id="side-panel"
        class="lg:w-[24rem] lg:flex lg:fixed lg:top-[64px] lg:right-0 lg:pr-4 z-[1000]"
      >
        <div class="pb-4 bg-gray-800/40 overflow-hidden w-screen lg:w-[23rem] lg:rounded-2xl shadow-inner shadow-white/[10%] lg:border border-white/[15%]">
          <div
            :if={@channel.solving_challenge}
            class="hidden sm:block bg-gray-950 px-4 py-4 text-center"
          >
            <div class="font-medium text-base">
              <.link
                href="https://console.algora.io/challenges/tsperf"
                class="font-semibold text-green-300 hover:underline"
              >
                Solving the $15,000 TSPerf Challenge
              </.link>
            </div>
            <div class="pt-1.5 font-medium text-sm">
              sponsored by
            </div>
            <div class="pt-2.5 mx-auto grid max-w-6xl gap-4 text-center grid-cols-3">
              <a
                target="_blank"
                rel="noopener"
                class="flex h-full flex-1 flex-col items-center text-white no-underline hover:no-underline"
                href="https://unkey.com"
              >
                <img
                  src="https://console.algora.io/banners/unkey.png"
                  alt="Unkey"
                  class="-mt-1 h-8 w-auto saturate-0"
                />
              </a>
              <a
                target="_blank"
                rel="noopener"
                class="flex h-full flex-1 flex-col items-center text-white no-underline hover:no-underline"
                href="https://scalar.com"
              >
                <img
                  src="https://console.algora.io/banners/scalar.png"
                  alt="Scalar"
                  class="h-6 w-auto saturate-0"
                />
              </a>
              <a
                target="_blank"
                rel="noopener"
                class="flex h-full flex-1 flex-col items-center text-white no-underline hover:no-underline"
                href="https://tigrisdata.com"
              >
                <img
                  src="https://assets-global.website-files.com/657988158c7fb30f4d9ef37b/657990b61fd3a5d674cf2298_tigris-logo.svg"
                  alt="Tigris"
                  class="mt-1 h-6 w-auto saturate-0"
                />
              </a>
            </div>
          </div>
          <div>
            <ul class="pt-4 pb-2 flex items-center justify-center gap-2 mx-auto text-gray-400">
              <li :for={{tab, i} <- Enum.with_index(@tabs)}>
                <button
                  id={"side-panel-tab-#{tab}"}
                  class={[
                    "text-xs font-semibold uppercase tracking-wide",
                    i == 0 && "active-tab text-white pointer-events-none"
                  ]}
                  phx-click={
                    set_active_tab("#side-panel-tab-#{tab}")
                    |> set_active_content("#side-panel-content-#{tab}")
                  }
                >
                  <%= tab %>
                </button>
              </li>
            </ul>
          </div>
          <div>
            <div
              :for={{tab, i} <- Enum.with_index(@tabs)}
              id={"side-panel-content-#{tab}"}
              class={["side-panel-content", i != 0 && "hidden"]}
            >
              <div :if={tab == :transcript}>
                <div
                  id="show-transcript"
                  phx-click={
                    if(@can_edit,
                      do:
                        JS.hide(to: "#show-transcript")
                        |> JS.show(to: "#edit-transcript"),
                      else: nil
                    )
                  }
                >
                  <div class={[
                    "overflow-y-auto text-sm break-words flex-1 scrollbar-thin",
                    if(@can_edit,
                      do: "h-[calc(100vh-12rem)]",
                      else: "h-[calc(100vh-8.75rem)]"
                    )
                  ]}>
                    <div :for={subtitle <- @subtitles} id={"subtitle-#{subtitle.id}"} class="px-4">
                      <.link
                        class="font-semibold text-indigo-400"
                        navigate={
                          ~p"/#{@video.channel_handle}/#{@video.id}?t=#{trunc(subtitle.start)}"
                        }
                      >
                        <%= Library.to_hhmmss(subtitle.start) %>
                      </.link>
                      <span class="font-medium text-gray-100">
                        <%= subtitle.body %>
                      </span>
                    </div>
                  </div>

                  <div class="px-4">
                    <button
                      :if={@can_edit}
                      class="mt-2 w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-purple-600 hover:bg-purple-500 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-purple-400"
                    >
                      Edit
                    </button>
                  </div>
                </div>
                <.simple_form
                  :if={@can_edit}
                  id="edit-transcript"
                  for={@transcript_form}
                  phx-submit="save"
                  phx-update="ignore"
                  class="hidden h-full px-4"
                >
                  <.input
                    field={@transcript_form[:subtitles]}
                    type="textarea"
                    label="Edit transcript"
                    class="font-mono h-[calc(100vh-14.75rem)]"
                  />
                  <div class="grid grid-cols-2 gap-4">
                    <button
                      name="save"
                      value="naive"
                      class="w-full flex justify-center z-10 py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-purple-600 hover:bg-purple-500 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-purple-400"
                    >
                      Save naive
                    </button>
                    <button
                      name="save"
                      value="fast"
                      class="w-full flex justify-center z-10 py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-purple-600 hover:bg-purple-500 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-purple-400"
                    >
                      Save fast
                    </button>
                  </div>
                </.simple_form>
              </div>

              <div :if={tab == :chat}>
                <div
                  id="chat-messages"
                  phx-hook="Chat"
                  phx-update="stream"
                  class={[
                    "text-sm break-words flex-1 scrollbar-thin overflow-y-auto",
                    if(@channel.solving_challenge,
                      do: "h-[calc(100svh-56.25vw-432px)] sm:h-[calc(100vh-19.5rem)]",
                      else: "h-[calc(100svh-56.25vw-392px)] sm:h-[calc(100vh-12rem)]"
                    )
                  ]}
                >
                  <div
                    :for={{id, message} <- @streams.messages}
                    id={id}
                    class="group hover:bg-white/5 relative px-4"
                  >
                    <span class={"font-semibold #{if(system_message?(message), do: "text-emerald-400", else: "text-indigo-400")}"}>
                      <%= message.sender_handle %>:
                    </span>
                    <span class="font-medium text-gray-100">
                      <%= message.body %>
                    </span>
                    <button
                      :if={@current_user && Chat.can_delete?(@current_user, message)}
                      phx-click="delete"
                      phx-value-id={message.id}
                    >
                      <Heroicons.x_mark
                        solid
                        class="absolute top-0.5 right-0.5 h-4 w-4 text-red-400 opacity-0 group-hover:opacity-100"
                      />
                    </button>
                  </div>
                </div>
                <div class="px-4 fixed sm:relative bottom-0 w-full">
                  <.simple_form
                    :if={@current_user}
                    for={@chat_form}
                    phx-submit="send"
                    phx-change="validate"
                  >
                    <div class="flex items-center justify-between lg:pt-2 lg:pb-0 py-4 gap-4">
                      <div class="w-full">
                        <.input
                          field={@chat_form[:body]}
                          placeholder="Send a message"
                          autocomplete="off"
                        />
                      </div>
                      <button type="submit" class="lg:hidden">
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
                          class="h-10 w-10 p-2 bg-purple-600 rounded-full"
                        >
                          <path stroke="none" d="M0 0h24v24H0z" fill="none" /><path d="M10 14l11 -11" /><path d="M21 3l-6.5 18a.55 .55 0 0 1 -1 0l-3.5 -7l-7 -3.5a.55 .55 0 0 1 0 -1l18 -6.5" />
                        </svg>
                      </button>
                    </div>
                  </.simple_form>
                  <div :if={!@current_user} class="lg:pt-2 lg:pb-0 py-4">
                    <a
                      :if={@authorize_url}
                      href={@authorize_url}
                      class="w-full flex items-center gap-4 justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-purple-600 hover:bg-purple-500 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-purple-400"
                    >
                      <svg
                        width="98"
                        height="96"
                        xmlns="http://www.w3.org/2000/svg"
                        class="h-6 w-6 -ml-2"
                        viewBox="0 0 98 96"
                      >
                        <path
                          fill-rule="evenodd"
                          clip-rule="evenodd"
                          d="M48.854 0C21.839 0 0 22 0 49.217c0 21.756 13.993 40.172 33.405 46.69 2.427.49 3.316-1.059 3.316-2.362 0-1.141-.08-5.052-.08-9.127-13.59 2.934-16.42-5.867-16.42-5.867-2.184-5.704-5.42-7.17-5.42-7.17-4.448-3.015.324-3.015.324-3.015 4.934.326 7.523 5.052 7.523 5.052 4.367 7.496 11.404 5.378 14.235 4.074.404-3.178 1.699-5.378 3.074-6.6-10.839-1.141-22.243-5.378-22.243-24.283 0-5.378 1.94-9.778 5.014-13.2-.485-1.222-2.184-6.275.486-13.038 0 0 4.125-1.304 13.426 5.052a46.97 46.97 0 0 1 12.214-1.63c4.125 0 8.33.571 12.213 1.63 9.302-6.356 13.427-5.052 13.427-5.052 2.67 6.763.97 11.816.485 13.038 3.155 3.422 5.015 7.822 5.015 13.2 0 18.905-11.404 23.06-22.324 24.283 1.78 1.548 3.316 4.481 3.316 9.126 0 6.6-.08 11.897-.08 13.526 0 1.304.89 2.853 3.316 2.364 19.412-6.52 33.405-24.935 33.405-46.691C97.707 22 75.788 0 48.854 0z"
                          fill="#fff"
                        />
                      </svg>
                      <span>Sign in to chat</span>
                    </a>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </aside>

      <section class="hidden lg:block">
        <h2 class="text-gray-400 text-xs font-medium uppercase tracking-wide px-4 pt-4">
          Library
        </h2>
        <.playlist id="playlist" videos={@streams.videos} />
      </section>
    </div>
    """
  end

  @impl true
  def mount(
        %{"channel_handle" => channel_handle, "video_id" => video_id} = params,
        _session,
        socket
      ) do
    %{current_user: current_user} = socket.assigns

    channel =
      Accounts.get_user_by!(handle: channel_handle)
      |> Library.get_channel!()

    video = Library.get_video!(video_id)

    if connected?(socket) do
      Library.subscribe_to_livestreams()
      Library.subscribe_to_channel(channel)
      Chat.subscribe_to_room(video)

      Presence.track_user(channel_handle, %{
        id: if(current_user, do: current_user.handle, else: "")
      })

      Presence.subscribe(channel_handle)
    end

    videos = Library.list_channel_videos(channel, 50)

    subtitles = Library.list_subtitles(%Library.Video{id: video_id})

    data = %{}

    {:ok, encoded_subtitles} =
      subtitles
      |> Enum.map(&%{id: &1.id, start: &1.start, end: &1.end, body: &1.body})
      |> Jason.encode(pretty: true)

    types = %{subtitles: :string}

    transcript_changeset =
      {data, types}
      |> Ecto.Changeset.cast(%{subtitles: encoded_subtitles}, Map.keys(types))

    tabs = [:chat] |> append_if(length(subtitles) > 0, :transcript)

    socket =
      socket
      |> assign(
        channel: channel,
        owns_channel?: current_user && Library.owns_channel?(current_user, channel),
        videos_count: Enum.count(videos),
        video: video,
        subtitles: subtitles,
        tabs: tabs,
        # TODO: reenable once fully implemented
        # associated segments need to be removed from db & vectorstore
        can_edit: false,
        transcript_form: to_form(transcript_changeset, as: :data),
        chat_form: to_form(Chat.change_message(%Chat.Message{}))
      )
      |> stream(:videos, videos)
      |> stream(:messages, Chat.list_messages(video))
      |> stream(:presences, Presence.list_online_users(channel_handle))

    if connected?(socket), do: send(self(), {:play, {video, params["t"]}})

    {:ok, socket}
  end

  @impl true
  def handle_params(params, url, socket) do
    %{path: path} = URI.parse(url)
    LayoutComponent.hide_modal()

    {:noreply,
     socket
     |> assign(authorize_url: Algora.Github.authorize_url(path))
     |> apply_action(socket.assigns.live_action, params)}
  end

  @impl true
  def handle_info({:play, {video, t}}, socket) do
    socket =
      socket
      |> push_event("play_video", %{
        url: video.url,
        title: video.title,
        player_type: Library.player_type(video),
        channel_name: video.channel_name,
        current_time: t
      })
      |> push_event("join_chat", %{id: video.id})

    {:noreply, socket}
  end

  def handle_info({Presence, {:join, presence}}, socket) do
    {:noreply, stream_insert(socket, :presences, presence)}
  end

  def handle_info({Presence, {:leave, presence}}, socket) do
    if presence.metas == [] do
      {:noreply, stream_delete(socket, :presences, presence)}
    else
      {:noreply, stream_insert(socket, :presences, presence)}
    end
  end

  def handle_info(
        {Storage, %Library.Events.ThumbnailsGenerated{video: video}},
        socket
      ) do
    {:noreply,
     if video.user_id == socket.assigns.channel.user_id do
       socket
       |> stream_insert(:videos, video, at: 0)
     else
       socket
     end}
  end

  def handle_info(
        {Library, %Library.Events.LivestreamStarted{video: video}},
        socket
      ) do
    %{channel: channel} = socket.assigns

    {:noreply,
     if video.user_id == channel.user_id do
       socket
       |> assign(channel: %{channel | is_live: true})
       |> stream_insert(:videos, video, at: 0)
     else
       socket
     end}
  end

  def handle_info(
        {Library, %Library.Events.LivestreamEnded{video: video}},
        socket
      ) do
    %{channel: channel} = socket.assigns

    {:noreply,
     if video.user_id == channel.user_id do
       socket
       |> assign(channel: %{channel | is_live: false})
       |> stream_insert(:videos, video)
     else
       socket
     end}
  end

  def handle_info(
        {Chat, %Chat.Events.MessageDeleted{message: message}},
        socket
      ) do
    {:noreply, socket |> stream_delete(:messages, message)}
  end

  def handle_info({Chat, %Chat.Events.MessageSent{message: message}}, socket) do
    {:noreply, socket |> stream_insert(:messages, message)}
  end

  def handle_info({Library, _}, socket), do: {:noreply, socket}

  defp fmt(num) do
    chars = num |> Integer.to_string() |> String.to_charlist()
    {h, t} = Enum.split(chars, rem(length(chars), 3))
    t = t |> Enum.chunk_every(3) |> Enum.join(",")

    case {h, t} do
      {~c"", _} -> t
      {_, ""} -> "#{h}"
      _ -> "#{h}," <> t
    end
  end

  @impl true
  def handle_event("validate", %{"message" => %{"body" => ""}}, socket), do: {:noreply, socket}

  def handle_event("validate", %{"message" => params}, socket) do
    form =
      %Chat.Message{}
      |> Chat.change_message(params)
      |> Map.put(:action, :insert)
      |> to_form()

    {:noreply, assign(socket, chat_form: form)}
  end

  def handle_event("send", %{"message" => %{"body" => ""}}, socket), do: {:noreply, socket}

  def handle_event("send", %{"message" => params}, socket) do
    %{current_user: current_user, video: video} = socket.assigns

    case Chat.create_message(current_user, video, params) do
      {:ok, message} ->
        # HACK:
        message = Chat.get_message!(message.id)
        Chat.broadcast_message_sent!(message)
        {:noreply, assign(socket, chat_form: to_form(Chat.change_message(%Chat.Message{})))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, chat_form: to_form(changeset))}
    end
  end

  def handle_event("save", %{"data" => %{"subtitles" => subtitles}, "save" => save_type}, socket) do
    {time, count} = :timer.tc(&save/2, [save_type, subtitles])
    msg = "Updated #{count} subtitles in #{fmt(round(time / 1000))} ms"

    {:noreply, socket |> put_flash(:info, msg)}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    %{current_user: current_user} = socket.assigns
    message = Chat.get_message!(id)

    if current_user && Chat.can_delete?(current_user, message) do
      {:ok, message} = Chat.delete_message(message)
      Chat.broadcast_message_deleted!(message)
      {:noreply, socket}
    else
      {:noreply, socket |> put_flash(:error, "You can't do that")}
    end
  end

  defp save("naive", subtitles) do
    Library.save_subtitles(subtitles)
  end

  defp save("fast", subtitles) do
    Fly.Postgres.rpc_and_wait(Library, :save_subtitles, [subtitles])
  end

  defp set_active_content(js \\ %JS{}, to) do
    js
    |> JS.hide(to: ".side-panel-content")
    |> JS.show(to: to)
  end

  defp set_active_tab(js \\ %JS{}, tab) do
    js
    |> JS.remove_class("active-tab text-white pointer-events-none",
      to: "#side-panel .active-tab"
    )
    |> JS.add_class("active-tab text-white pointer-events-none", to: tab)
  end

  defp system_message?(%Chat.Message{} = message) do
    message.sender_handle == "algora"
  end

  defp append_if(list, cond, extra) do
    if cond, do: list ++ [extra], else: list
  end

  defp apply_action(socket, :stream, _params) do
    if socket.assigns.owns_channel? do
      socket
      |> assign(:page_title, "Start streaming")
      |> show_stream_modal()
    else
      socket
      |> put_flash(:error, "You can't do that")
      |> redirect(to: channel_path(socket.assigns.current_user))
    end
  end

  defp apply_action(socket, :show, params) do
    socket
    |> assign(:page_title, socket.assigns.channel.name || params["channel_handle"])
    |> assign(:page_description, socket.assigns.video.title)
    |> assign(:page_image, Library.get_og_image_url(socket.assigns.video))
  end

  defp show_stream_modal(socket) do
    LayoutComponent.show_modal(StreamFormComponent, %{
      id: :stream,
      confirm: {"Save", type: "submit", form: "stream-form"},
      patch: channel_path(socket.assigns.current_user),
      video: socket.assigns.video,
      title: socket.assigns.page_title,
      current_user: socket.assigns.current_user,
      changeset: Accounts.change_settings(socket.assigns.current_user, %{})
    })

    socket
  end
end
