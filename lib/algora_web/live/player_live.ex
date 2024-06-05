defmodule AlgoraWeb.PlayerLive do
  use AlgoraWeb, {:live_view, container: {:div, []}}

  alias Algora.Library

  on_mount {AlgoraWeb.UserAuth, :current_user}

  @impl true
  def render(assigns) do
    ~H"""
    <div class="lg:px-4">
      <div class="w-full hidden lg:pr-[24rem]">
        <video
          id="video-player"
          phx-hook="VideoPlayer"
          class="video-js vjs-default-skin aspect-video h-full w-full flex-1 lg:rounded-2xl overflow-hidden"
          controls
        />
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket, layout: false, temporary_assigns: [video: nil]}
  end

  @impl true
  def handle_info({Library, _}, socket), do: {:noreply, socket}
end
