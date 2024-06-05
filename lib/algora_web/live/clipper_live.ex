defmodule AlgoraWeb.ClipperLive do
  use AlgoraWeb, {:live_view, container: {:div, []}}

  alias Algora.{Library, Clipper, Accounts}

  on_mount {AlgoraWeb.UserAuth, :current_user}

  @impl true
  def render(assigns) do
    ~H"""
    <div
      :if={@video && @current_user && Accounts.admin?(@current_user)}
      class="max-w-sm fixed left-1 bottom-1 z-[1000] bg-gray-800 p-2 rounded-xl"
    >
      <div
        :if={@ffmpeg_cmd}
        class="pb-2 whitespace-nowrap font-semibold text-sm text-green-300 font-mono overflow-x-auto"
      >
        <%= @ffmpeg_cmd %>
      </div>
      <form class="mx-auto" phx-submit="clip">
        <div class="relative space-y-4">
          <div class="grid grid-cols-3 gap-2">
            <div class="grid grid-cols-3 rounded-lg ring-2 ring-purple-500 overflow-hidden">
              <input
                inputmode="numeric"
                pattern="[0-9]*"
                id="from-hh"
                name="from-hh"
                autocomplete="off"
                class="w-full pl-4 text-sm bg-gray-950/75 placeholder-purple-300 text-white focus:outline-none"
                placeholder="hh"
              />
              <input
                inputmode="numeric"
                pattern="[0-9]*"
                id="from-mm"
                name="from-mm"
                autocomplete="off"
                class="w-full pl-2 text-sm bg-gray-950/75 placeholder-purple-300 text-white focus:outline-none"
                placeholder="mm"
              />
              <input
                inputmode="numeric"
                pattern="[0-9]*"
                id="from-ss"
                name="from-ss"
                autocomplete="off"
                class="w-full pl-2 text-sm bg-gray-950/75 placeholder-purple-300 text-white focus:outline-none"
                placeholder="ss"
              />
            </div>
            <div class="grid grid-cols-3 rounded-lg ring-2 ring-purple-500 overflow-hidden">
              <input
                inputmode="numeric"
                pattern="[0-9]*"
                id="to-hh"
                name="to-hh"
                autocomplete="off"
                class="w-full pl-4 text-sm bg-gray-950/75 placeholder-purple-300 text-white focus:outline-none"
                placeholder="hh"
              />
              <input
                inputmode="numeric"
                pattern="[0-9]*"
                id="to-mm"
                name="to-mm"
                autocomplete="off"
                class="w-full pl-2 text-sm bg-gray-950/75 placeholder-purple-300 text-white focus:outline-none"
                placeholder="mm"
              />
              <input
                inputmode="numeric"
                pattern="[0-9]*"
                id="to-ss"
                name="to-ss"
                autocomplete="off"
                class="w-full pl-2 text-sm bg-gray-950/75 placeholder-purple-300 text-white focus:outline-none"
                placeholder="ss"
              />
            </div>
            <button
              type="submit"
              class="w-full text-white focus:ring-4 focus:outline-none font-medium rounded-lg text-sm px-4 py-2 bg-purple-600 hover:bg-purple-700 focus:ring-purple-800"
            >
              Clip
            </button>
          </div>
        </div>
      </form>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:video, nil)
     |> assign(:ffmpeg_cmd, nil), layout: false}
  end

  @impl true
  def handle_event("video_loaded", %{"id" => id}, socket) do
    {:noreply,
     socket
     |> assign(:video, Library.get_video!(id))}
  end

  def handle_event(
        "clip",
        %{
          "from-hh" => from_hh,
          "from-mm" => from_mm,
          "from-ss" => from_ss,
          "to-hh" => to_hh,
          "to-mm" => to_mm,
          "to-ss" => to_ss
        },
        socket
      ) do
    from = to_time(from_hh, :hours) + to_time(from_mm, :minutes) + to_time(from_ss, :seconds)
    to = to_time(to_hh, :hours) + to_time(to_mm, :minutes) + to_time(to_ss, :seconds)

    cmd = Clipper.create_clip(socket.assigns.video, from, to)

    {:noreply,
     socket
     |> assign(:ffmpeg_cmd, cmd)}
  end

  defp to_time("", _timeframe), do: 0
  defp to_time(n, :seconds), do: String.to_integer(n)
  defp to_time(n, :minutes), do: String.to_integer(n) * 60
  defp to_time(n, :hours), do: String.to_integer(n) * 3600
end
