defmodule AlgoraWeb.ChannelLive do
  use AlgoraWeb, :live_view
  require Logger

  alias Algora.{Accounts, Library, Storage}
  alias AlgoraWeb.{LayoutComponent, Presence}
  alias AlgoraWeb.ChannelLive.StreamFormComponent

  def render(assigns) do
    ~H"""
    <%!-- <:actions>
        <.button
          :if={@owns_channel? && not @channel.is_live}
          id="stream-btn"
          primary
          patch={channel_stream_path(@current_user)}
        >
          <svg
            xmlns="http://www.w3.org/2000/svg"
            class="-ml-1 w-6 h-6 inline-block"
            width="24"
            height="24"
            viewBox="0 0 24 24"
            stroke-width="1.5"
            stroke="currentColor"
            fill="none"
            stroke-linecap="round"
            stroke-linejoin="round"
          >
            <path stroke="none" d="M0 0h24v24H0z" fill="none" /><path d="M12 12l0 .01" /><path d="M14.828 9.172a4 4 0 0 1 0 5.656" /><path d="M17.657 6.343a8 8 0 0 1 0 11.314" /><path d="M9.168 14.828a4 4 0 0 1 0 -5.656" /><path d="M6.337 17.657a8 8 0 0 1 0 -11.314" />
          </svg>
          <span class="ml-2">
            Start streaming!
          </span>
        </.button>
      </:actions> --%>

    <div>
      <div class="border-b border-gray-700 px-4 py-4">
        <figure :if={@channel.is_live} class="relative isolate -mt-4 pt-4 pb-4">
          <svg
            viewBox="0 0 162 128"
            fill="none"
            aria-hidden="true"
            class="absolute left-0 top-0 -z-10 h-12 stroke-white/75"
          >
            <path
              id="b56e9dab-6ccb-4d32-ad02-6b4bb5d9bbeb"
              d="M65.5697 118.507L65.8918 118.89C68.9503 116.314 71.367 113.253 73.1386 109.71C74.9162 106.155 75.8027 102.28 75.8027 98.0919C75.8027 94.237 75.16 90.6155 73.8708 87.2314C72.5851 83.8565 70.8137 80.9533 68.553 78.5292C66.4529 76.1079 63.9476 74.2482 61.0407 72.9536C58.2795 71.4949 55.276 70.767 52.0386 70.767C48.9935 70.767 46.4686 71.1668 44.4872 71.9924L44.4799 71.9955L44.4726 71.9988C42.7101 72.7999 41.1035 73.6831 39.6544 74.6492C38.2407 75.5916 36.8279 76.455 35.4159 77.2394L35.4047 77.2457L35.3938 77.2525C34.2318 77.9787 32.6713 78.3634 30.6736 78.3634C29.0405 78.3634 27.5131 77.2868 26.1274 74.8257C24.7483 72.2185 24.0519 69.2166 24.0519 65.8071C24.0519 60.0311 25.3782 54.4081 28.0373 48.9335C30.703 43.4454 34.3114 38.345 38.8667 33.6325C43.5812 28.761 49.0045 24.5159 55.1389 20.8979C60.1667 18.0071 65.4966 15.6179 71.1291 13.7305C73.8626 12.8145 75.8027 10.2968 75.8027 7.38572C75.8027 3.6497 72.6341 0.62247 68.8814 1.1527C61.1635 2.2432 53.7398 4.41426 46.6119 7.66522C37.5369 11.6459 29.5729 17.0612 22.7236 23.9105C16.0322 30.6019 10.618 38.4859 6.47981 47.558L6.47976 47.558L6.47682 47.5647C2.4901 56.6544 0.5 66.6148 0.5 77.4391C0.5 84.2996 1.61702 90.7679 3.85425 96.8404L3.8558 96.8445C6.08991 102.749 9.12394 108.02 12.959 112.654L12.959 112.654L12.9646 112.661C16.8027 117.138 21.2829 120.739 26.4034 123.459L26.4033 123.459L26.4144 123.465C31.5505 126.033 37.0873 127.316 43.0178 127.316C47.5035 127.316 51.6783 126.595 55.5376 125.148L55.5376 125.148L55.5477 125.144C59.5516 123.542 63.0052 121.456 65.9019 118.881L65.5697 118.507Z"
            >
            </path>
            <use href="#b56e9dab-6ccb-4d32-ad02-6b4bb5d9bbeb" x="86"></use>
          </svg>
          <blockquote class="text-xl font-semibold leading-8 text-white sm:text-2xl sm:leading-9">
            <p><%= @channel.tagline %></p>
          </blockquote>
        </figure>

        <div class="flex flex-col items-start justify-start md:flex-row md:items-center md:justify-between gap-8">
          <div class="flex items-center gap-4">
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
          </div>
          <div class="flex gap-6">
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

      <h2 class="text-gray-400 text-xs font-medium uppercase tracking-wide px-4 pt-4">
        Library
      </h2>
      <.playlist id="playlist" videos={@streams.videos} />
    </div>
    """
  end

  def mount(%{"channel_handle" => channel_handle}, _session, socket) do
    %{current_user: current_user} = socket.assigns

    channel =
      Accounts.get_user_by!(handle: channel_handle)
      |> Library.get_channel!()

    if connected?(socket) do
      Library.subscribe_to_livestreams()
      Library.subscribe_to_channel(channel)

      Presence.track_user(channel_handle, %{
        id: if(current_user, do: current_user.handle, else: "")
      })

      Presence.subscribe(channel_handle)
    end

    videos = Library.list_channel_videos(channel, 50)

    socket =
      socket
      |> assign(
        channel: channel,
        owns_channel?: current_user && Library.owns_channel?(current_user, channel),
        videos_count: Enum.count(videos)
      )
      |> stream(:videos, videos)
      |> stream(:presences, Presence.list_online_users(channel_handle))

    {:ok, socket}
  end

  def handle_params(params, _url, socket) do
    LayoutComponent.hide_modal()
    {:noreply, socket |> apply_action(socket.assigns.live_action, params)}
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

  def handle_info({Library, _}, socket), do: {:noreply, socket}

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
    user = Accounts.get_user!(socket.assigns.channel.user_id)

    socket
    |> assign(:page_title, socket.assigns.channel.name || params["channel_handle"])
    |> assign(:page_description, socket.assigns.channel.tagline)
    |> assign(:page_image, Library.get_thumbnail_url(user))
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
