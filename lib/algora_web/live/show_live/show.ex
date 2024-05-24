defmodule AlgoraWeb.ShowLive.Show do
  use AlgoraWeb, :live_view

  alias Algora.{Shows, Library, Events}
  alias Algora.Accounts
  alias AlgoraWeb.LayoutComponent

  @impl true
  def render(assigns) do
    ~H"""
    <div class="text-white min-h-screen p-8">
      <div class="flex flex-col md:grid md:grid-cols-3 gap-6">
        <div class="md:col-span-1 bg-white/5 ring-1 ring-white/15 rounded-lg p-6 space-y-6">
          <img src={@show.image_url} class="h-[250px] rounded-lg" />
          <div class="space-y-2">
            <div class="flex items-center space-x-2">
              <span class="font-bold"><%= @channel.name %></span>
              <.link
                :if={@channel.twitter_url}
                target="_blank"
                rel="noopener noreferrer"
                href={@channel.twitter_url}
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
            <.button :if={@current_user} phx-click="toggle_subscription">
              <%= if @subscribed? do %>
                Unsubscribe
              <% else %>
                Subscribe
              <% end %>
            </.button>
            <.button :if={!@current_user && @authorize_url}>
              <.link navigate={@authorize_url}>
                Subscribe
              </.link>
            </.button>
          </div>
          <div :if={@attendees_count > 0} class="border-t border-white/15 pt-6 space-y-4">
            <div>
              <span class="font-medium"><%= @attendees_count %> Attending</span>
            </div>
            <div>
              <div class="flex -space-x-1">
                <span
                  :for={attendee <- @attendees |> Enum.take(@max_attendee_avatars_count)}
                  class="relative ring-4 ring-gray-950 flex h-10 w-10 shrink-0 overflow-hidden rounded-full"
                >
                  <img
                    class="aspect-square h-full w-full"
                    alt={attendee.user_display_name}
                    src={attendee.user_avatar_url}
                  />
                </span>
              </div>
              <div class="mt-2">
                <span
                  :for={
                    {attendee, i} <-
                      Enum.with_index(@attendees) |> Enum.take(@max_attendee_names_count)
                  }
                  class="font-medium"
                >
                  <span :if={i != 0} class="-ml-1">, </span><span><%= attendee.user_display_name %></span>
                </span>
                <span :if={@attendees_count > @max_attendee_names_count} class="font-medium">
                  and
                  <span :if={@attendees_count == @max_attendee_names_count + 1}>
                    <%= @attendees |> Enum.at(@max_attendee_names_count) %>
                  </span>
                  <span :if={@attendees_count != @max_attendee_names_count + 1}>
                    <%= @attendees_count - @max_attendee_names_count %> others
                  </span>
                </span>
              </div>
            </div>
          </div>
        </div>
        <div class="md:col-span-2 space-y-6">
          <div class="bg-white/5 ring-1 ring-white/15 rounded-lg p-6 space-y-6">
            <div class="flex flex-col md:flex-row md:items-start md:justify-between gap-6">
              <div>
                <h1 class="text-4xl font-bold"><%= @show.title %></h1>
                <div :if={@show.description} class="mt-4 space-y-4">
                  <div>
                    <h2 class="text-2xl font-bold">About</h2>
                    <p class="typography whitespace-pre-wrap"><%= @show.description %></p>
                  </div>
                </div>
              </div>

              <div class="space-y-2 w-full max-w-sm">
                <div :if={@show.scheduled_for} class="bg-gray-950/75 p-4 rounded-lg">
                  <div class="flex items-center justify-between">
                    <div class="flex items-center space-x-4">
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
                      <div class="shrink-0">
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
                    <.button :if={@current_user && !@rsvpd?} phx-click="toggle_rsvp">
                      Attend
                    </.button>
                    <.button
                      :if={@rsvpd?}
                      disabled
                      class="bg-green-400 hover:bg-green-400 disabled:opacity-100 text-green-950 flex items-center active:text-green-950"
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
                        class="h-5 w-5 -ml-0.5"
                      >
                        <path stroke="none" d="M0 0h24v24H0z" fill="none" /><path d="M5 12l5 5l10 -10" />
                      </svg>
                      <span class="ml-1">Attending</span>
                    </.button>
                    <.button :if={!@current_user && @authorize_url}>
                      <.link navigate={@authorize_url}>
                        Attend
                      </.link>
                    </.button>
                  </div>
                </div>
                <.link
                  href={@show.url || ~p"/#{@channel.handle}/latest"}
                  target="_blank"
                  rel="noopener"
                  class="block bg-gray-950/75 p-4 rounded-lg"
                >
                  <div class="flex items-center justify-between">
                    <div class="flex items-center space-x-4">
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
                          <%= @show.url || "tv.algora.io/#{@channel.handle}/latest" %>
                        </div>
                      </div>
                    </div>
                  </div>
                </.link>
              </div>
            </div>
          </div>
          <div class="bg-white/5 ring-1 ring-white/15 rounded-lg p-6 space-y-6">
            <h2 class="pt-4 text-2xl font-bold">Past sessions</h2>
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
    </div>
    <.modal
      :if={@live_action in [:new, :edit]}
      id="show-modal"
      show
      on_cancel={JS.patch(~p"/shows/#{@show.slug}")}
    >
      <.live_component
        module={AlgoraWeb.ShowLive.FormComponent}
        id={@show.id || :new}
        title={@page_title}
        action={@live_action}
        show={@show}
      />
    </.modal>
    """
  end

  @impl true
  def mount(%{"slug" => slug}, _session, socket) do
    %{current_user: current_user} = socket.assigns

    show = Shows.get_show_by_fields!(slug: slug)

    channel = Accounts.get_user(show.user_id) |> Library.get_channel!()

    videos = Library.list_channel_videos(channel, 50)

    {:ok,
     socket
     |> assign_attendees(show)
     |> assign(:show, show)
     |> assign(:channel, channel)
     |> assign(:max_attendee_avatars_count, 5)
     |> assign(:max_attendee_names_count, 2)
     |> assign(:subscribed?, Events.subscribed?(current_user, channel))
     |> assign(:rsvpd?, Events.rsvpd?(current_user, channel))
     |> stream(:videos, videos)}
  end

  @impl true
  def handle_params(params, url, socket) do
    %{path: path} = URI.parse(url)
    LayoutComponent.hide_modal()

    {:noreply,
     socket
     |> assign(:authorize_url, Algora.Github.authorize_url(path))
     |> apply_action(socket.assigns.live_action, params)}
  end

  @impl true
  def handle_event("toggle_subscription", _params, socket) do
    Events.toggle_subscription_event(socket.assigns.current_user, socket.assigns.show)

    {:noreply,
     socket
     |> assign(:subscribed?, !socket.assigns.subscribed?)}
  end

  def handle_event("toggle_rsvp", _params, socket) do
    Events.toggle_rsvp_event(socket.assigns.current_user, socket.assigns.show)

    {:noreply,
     socket
     |> assign_attendees(socket.assigns.show)
     |> assign(:rsvpd?, !socket.assigns.rsvpd?)}
  end

  @impl true
  def handle_info({AlgoraWeb.ShowLive.FormComponent, {:saved, show}}, socket) do
    {:noreply, socket |> assign(:show, show)}
  end

  defp apply_action(socket, :show, %{"slug" => slug}) do
    show = Shows.get_show_by_fields!(slug: slug)

    socket
    |> assign(:page_title, show.title)
    |> assign(:page_description, show.description)
    |> assign(:page_image, show.og_image_url)
  end

  defp apply_action(socket, :edit, %{"slug" => slug}) do
    show = Shows.get_show_by_fields!(slug: slug)

    socket
    |> assign(:page_title, show.title)
    |> assign(:page_description, show.description)
    |> assign(:page_image, show.og_image_url)
  end

  defp assign_attendees(socket, show) do
    attendees = Events.fetch_attendees(show)

    socket
    |> assign(:attendees, attendees)
    |> assign(:attendees_count, length(attendees))
  end
end
