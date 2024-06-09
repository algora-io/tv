defmodule AlgoraWeb.PlayerLive do
  use AlgoraWeb, {:live_view, container: {:div, []}}

  alias AlgoraWeb.{PlayerComponent}

  on_mount {AlgoraWeb.UserAuth, :current_user}

  @impl true
  def render(assigns) do
    ~H"""
    <div class="lg:px-4">
      <div class="w-full hidden lg:pr-[24rem]">
        <.live_component module={PlayerComponent} id="sticky-player" current_user={@current_user} />
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket, layout: false, temporary_assigns: []}
  end

  @impl true
  def handle_info({:play, %{video: video}} = _args, socket) do
    send_update(PlayerComponent, %{
      id: "sticky-player",
      video: video,
      current_user: socket.assigns.current_user
    })

    {:noreply, socket}
  end

  def handle_info(_args, socket), do: {:noreply, socket}
end
