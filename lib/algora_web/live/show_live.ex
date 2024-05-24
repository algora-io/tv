defmodule AlgoraWeb.ShowLive do
  use AlgoraWeb, :live_view
  require Logger
  # import Faker

  alias Algora.Library
  alias AlgoraWeb.LayoutComponent

  def render(assigns) do
    ~H"""
    <div class="text-white min-h-screen p-8" data-id="1">
      <div class="grid grid-cols-3 gap-8" data-id="2">
        <div class="col-span-1 bg-white/5 ring-1 ring-white/15 rounded-lg p-6 space-y-6" data-id="3">
          <div class="bg-gray-950/75 p-4 rounded-lg text-center" data-id="4">
            <h2 class="text-2xl font-bold" data-id="5">Request</h2>
            <h2 class="text-2xl font-bold" data-id="6">For</h2>
            <h2 class="text-2xl font-bold" data-id="7">Comments</h2>
            <div class="bg-red-600 inline-block px-3 py-1 rounded-full text-sm mt-4" data-id="8">
              LIVE
            </div>
          </div>
          <div class="space-y-2" data-id="9">
            <div class="flex items-center space-x-2" data-id="23">
              <span class="font-bold" data-id="24"><%= @show.host.display_name %></span>
              <.link :if={@show.host.twitter_url} href={@show.host.twitter_url}>
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
                  class="h-5 w-5 text-[#1DA1F2]"
                  data-id="25"
                >
                  <path d="M22 4s-.7 2.1-2 3.4c1.6 10-9.4 17.3-18 11.6 2.2.1 4.4-.6 6-2C3 15.5.5 9.6 3 5c2.2 2.6 5.6 4.1 9 4-.9-4.2 4-6.6 7-3.8 1.1 0 3-1.2 3-1.2z">
                  </path>
                </svg>
              </.link>
            </div>
            <.button>
              Subscribe
            </.button>
          </div>
          <div class="border-t border-[#374151] pt-6 space-y-4" data-id="17">
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
          <div>
            <h1 class="text-4xl font-bold"><%= @show.title %></h1>
          </div>
          <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div class="space-y-2">
              <div class="bg-gray-950/75 p-4 rounded-lg">
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
                      class="h-6 w-6 text-[#EAB308]"
                    >
                      <path d="M8 2v4"></path>
                      <path d="M16 2v4"></path>
                      <rect width="18" height="18" x="3" y="4" rx="2"></rect>
                      <path d="M3 10h18"></path>
                    </svg>
                    <div>
                      <div class="text-sm">Friday, May 17</div>
                      <div class="text-sm">7:00 p.m. - 8:00 p.m. GMT+3</div>
                    </div>
                  </div>
                  <div class="inline-flex w-fit items-center whitespace-nowrap rounded-full border px-2.5 py-0.5 text-xs font-semibold transition-colors focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2 border-transparent bg-secondary text-secondary-foreground hover:bg-secondary/80">
                    MAY 17
                  </div>
                </div>
              </div>
              <div class="bg-gray-950/75 p-4 rounded-lg">
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
                      class="h-6 w-6 text-[#EAB308]"
                    >
                      <circle cx="12" cy="12" r="10"></circle>
                      <polyline points="12 6 12 12 16 14"></polyline>
                    </svg>
                    <div>
                      <div class="text-sm font-bold">Past Event</div>
                      <div class="text-sm">This event ended 6 days ago.</div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
            <div class="space-y-4">
              <div class="text-sm">
                Welcome! To join the event, please register below.
              </div>
              <button class="inline-flex items-center justify-center whitespace-nowrap rounded-md text-sm font-medium ring-offset-background transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 bg-primary text-primary-foreground hover:bg-primary/90 h-10 px-4 py-2">
                Register
              </button>
            </div>
          </div>
          <div class="space-y-4">
            <div class="border-t border-[#374151] pt-4">
              <h2 class="text-2xl font-bold">About Event</h2>
              <p class="text-sm mt-2">Deeeemoooo time :)</p>
              <p class="text-sm mt-2">
                Founders demo'ing their prototypes and new products
              </p>
              <p class="text-sm mt-2">
                I will give investor POV feedback if useful!
              </p>
            </div>
          </div>
          <.playlist id="playlist" videos={@streams.videos} />
        </div>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    %{current_user: current_user} = socket.assigns

    # TODO:
    channel = current_user |> Library.get_channel!()

    videos = Library.list_channel_videos(channel, 50)

    show = %{
      title: "RFC 006 - Demos!",
      host: %{
        display_name: "Andreas Klinger",
        avatar_url: "https://avatars.githubusercontent.com/u/245833?v=4",
        twitter_url: "https://x.com/andreasklinger"
      }
    }

    attendees =
      1..5
      |> Enum.map(fn _ ->
        %{
          # display_name: Faker.name(),
          # avatar_url: Faker.Avatar.image_url()
          display_name: "Andreas Klinger",
          avatar_url: "https://avatars.githubusercontent.com/u/245833?v=4"
        }
      end)

    socket =
      socket
      |> assign(:show, show)
      |> assign(:attendees, attendees)
      |> stream(:videos, videos)

    {:ok, socket}
  end

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
