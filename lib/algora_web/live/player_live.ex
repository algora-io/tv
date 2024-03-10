defmodule AlgoraWeb.PlayerLive do
  use AlgoraWeb, {:live_view, container: {:div, []}}

  on_mount {AlgoraWeb.UserAuth, :current_user}

  def render(assigns) do
    ~H"""
    <div class="px-4 w-full hidden">
      <video
        id="video-player"
        phx-hook="VideoPlayer"
        class="video-js vjs-default-skin min-w-xl max-w-2xl aspect-video vjs-fluid h-full w-full flex-1 rounded-2xl overflow-hidden"
        controls
      />
    </div>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, socket, layout: false, temporary_assigns: []}
  end

  def handle_info({Library, _}, socket), do: {:noreply, socket}
end
