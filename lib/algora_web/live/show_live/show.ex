defmodule AlgoraWeb.ShowLive.Show do
  use AlgoraWeb, :live_view

  alias Algora.Shows
  alias Algora.Library
  alias AlgoraWeb.LayoutComponent

  @impl true
  def render(assigns) do
    ~H"""
    <div class="text-white min-h-screen p-8">
      <div class="grid grid-cols-3 gap-8">
        <div class="col-span-1 bg-white/5 ring-1 ring-white/15 rounded-lg p-6 space-y-6">
          <img src={@show.image_url} class="w-[250px] rounded-lg" />
          <div class="space-y-2">
            <div class="flex items-center space-x-2">
              <span class="font-bold"><%= @host.display_name %></span>
              <.link
                :if={@host.twitter_url}
                target="_blank"
                rel="noopener noreferrer"
                href={@host.twitter_url}
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
            <.button>
              Subscribe
            </.button>
          </div>
          <div class="border-t border-[#374151] pt-6 space-y-4">
            <div>
              <span class="font-medium"><%= length(@attendees) %> Attending</span>
            </div>
            <div>
              <div class="flex -space-x-1">
                <span
                  :for={attendee <- @attendees |> Enum.take(5)}
                  class="relative ring-4 ring-gray-950 flex h-10 w-10 shrink-0 overflow-hidden rounded-full"
                >
                  <img
                    class="aspect-square h-full w-full"
                    alt={attendee.display_name}
                    src={attendee.avatar_url}
                  />
                </span>
              </div>
              <div :if={length(@attendees) > 0} class="mt-2">
                <div>
                  <span :for={attendee <- @attendees |> Enum.take(2)} class="font-medium">
                    <%= attendee.display_name %>,
                  </span>
                </div>
                <span :if={length(@attendees) > 2} class="font-medium">
                  and <%= length(@attendees) - 2 %> others
                </span>
              </div>
            </div>
            <.button>
              Attend
            </.button>
          </div>
        </div>
        <div class="col-span-2 bg-white/5 ring-1 ring-white/15 rounded-lg p-6 space-y-6">
          <div class="flex items-start justify-between">
            <div>
              <h1 class="text-4xl font-bold"><%= @show.title %></h1>
              <div :if={@show.description} class="mt-4 space-y-4">
                <div>
                  <h2 class="text-2xl font-bold">About</h2>
                  <p class="typography whitespace-pre"><%= @show.description %></p>
                </div>
              </div>
            </div>

            <div class="space-y-2 w-full max-w-xs">
              <div :if={@show.scheduled_for} class="bg-gray-950/75 p-4 rounded-lg">
                <div class="flex items-center justify-between">
                  <div class="flex items-center space-x-2">
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
                      class="h-6 w-6 text-green-300"
                    >
                      <path d="M8 2v4"></path>
                      <path d="M16 2v4"></path>
                      <rect width="18" height="18" x="3" y="4" rx="2"></rect>
                      <path d="M3 10h18"></path>
                    </svg>
                    <div>
                      <div class="text-sm font-semibold">
                        <%= @show.scheduled_for
                        |> Timex.to_datetime("Etc/UTC")
                        |> Timex.Timezone.convert("America/New_York")
                        |> Timex.format!("{WDfull}, {Mshort} {D}") %>
                      </div>
                      <div class="text-sm">
                        <%= @show.scheduled_for
                        |> Timex.to_datetime("Etc/UTC")
                        |> Timex.Timezone.convert("America/New_York")
                        |> Timex.format!("{h12}:{m} {am}, Eastern Time") %>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
              <.link
                href={@show.url || ~p"/#{@host.handle}/latest"}
                target="_blank"
                rel="noopener"
                class="block bg-gray-950/75 p-4 rounded-lg"
              >
                <div class="flex items-center justify-between">
                  <div class="flex items-center space-x-2">
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
                      class="h-6 w-6 text-red-400"
                    >
                      <path stroke="none" d="M0 0h24v24H0z" fill="none" /><path d="M18.364 19.364a9 9 0 1 0 -12.728 0" /><path d="M15.536 16.536a5 5 0 1 0 -7.072 0" /><path d="M12 13m-1 0a1 1 0 1 0 2 0a1 1 0 1 0 -2 0" />
                    </svg>
                    <div>
                      <div class="text-sm font-semibold">Watch live</div>
                      <div class="text-sm">
                        <%= @show.url || "tv.algora.io/#{@host.handle}/latest" %>
                      </div>
                    </div>
                  </div>
                </div>
              </.link>
            </div>
          </div>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-6"></div>
          <h2 class="border-t border-[#374151] pt-4 text-2xl font-bold">Past sessions</h2>
          <div id="past-sessions" class="mt-3 flex gap-8 overflow-x-scroll" phx-update="stream">
            <div :for={{_id, video} <- @streams.videos} class="max-w-xs shrink-0 w-full">
              <.link class="cursor-pointer truncate" href={~p"/#{video.channel_handle}/#{video.id}"}>
                <.video_thumbnail video={video} class="rounded-2xl" />
                <div class="pt-2 text-base font-semibold truncate"><%= video.title %></div>
                <div class="text-gray-300 text-sm"><%= Timex.from_now(video.inserted_at) %></div>
              </.link>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def mount(%{"slug" => slug}, _session, socket) do
    %{current_user: current_user} = socket.assigns

    # TODO:
    channel = current_user |> Library.get_channel!()

    videos = Library.list_channel_videos(channel, 50)

    show = Shows.get_show_by_fields!(slug: slug)

    host = %{
      handle: "rfc",
      display_name: "Andreas Klinger",
      avatar_url: "https://avatars.githubusercontent.com/u/245833?v=4",
      twitter_url: "https://x.com/andreasklinger"
    }

    attendees =
      1..5
      |> Enum.map(fn _ ->
        %{
          display_name: "Andreas Klinger",
          avatar_url: "https://avatars.githubusercontent.com/u/245833?v=4"
        }
      end)

    socket =
      socket
      |> assign(:show, show)
      |> assign(:host, host)
      |> assign(:attendees, attendees)
      |> stream(:videos, videos)

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    LayoutComponent.hide_modal()
    {:noreply, socket |> apply_action(socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :show, _params) do
    socket
    |> assign(:page_title, "TODO")
    |> assign(:page_description, "TODO")
  end
end
