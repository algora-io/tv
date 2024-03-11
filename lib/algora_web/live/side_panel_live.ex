defmodule AlgoraWeb.SidePanelLive do
  use AlgoraWeb, {:live_view, container: {:div, []}}
  alias Algora.{Chat, Library}

  on_mount {AlgoraWeb.UserAuth, :current_user}

  def render(assigns) do
    tabs =
      [:chat]
      |> append_if(length(assigns.subtitles) > 0, :transcript)

    assigns = assigns |> assign(:tabs, tabs)

    ~H"""
    <aside id="side-panel" class="hidden fixed top-[64px] right-0 w-0 pr-4">
      <div class="p-4 bg-gray-800/40 w-[23rem] backdrop-blur-xl rounded-2xl shadow-inner shadow-white/[10%] border border-white/[15%]">
        <div>
          <ul class="pb-2 flex items-center justify-center gap-2 mx-auto text-gray-400">
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
                  JS.hide(to: "#show-transcript")
                  |> JS.show(to: "#edit-transcript")
                }
              >
                <div class={
                  [
                    "overflow-y-auto text-sm break-words flex-1",
                    # HACK:
                    if(@current_user.handle == "zaf",
                      do: "h-[calc(100vh-11rem)]",
                      else: "h-[calc(100vh-8.75rem)]"
                    )
                  ]
                }>
                  <div :for={subtitle <- @subtitles} id={"subtitle-#{subtitle.id}"}>
                    <span class="font-semibold text-indigo-400">
                      <%= Library.to_hhmmss(subtitle.start) %>
                    </span>
                    <span class="font-medium text-gray-100">
                      <%= subtitle.body %>
                    </span>
                  </div>
                </div>

                <button
                  :if={@current_user.handle == "zaf"}
                  class="mt-2 w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-purple-600 hover:bg-purple-500 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-purple-400"
                >
                  Edit
                </button>
              </div>
              <.simple_form
                :if={@current_user.handle == "zaf"}
                id="edit-transcript"
                for={@form}
                phx-submit="save"
                class="hidden h-full"
              >
                <.input
                  field={@form[:subtitles]}
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
                class="text-sm break-words flex-1 overflow-y-auto h-[calc(100vh-11rem)]"
              >
                <div :for={message <- @messages} id={"message-#{message.id}"}>
                  <span class={"font-semibold #{if(system_message?(message), do: "text-emerald-400", else: "text-indigo-400")}"}>
                    <%= message.sender_handle %>:
                  </span>
                  <span class="font-medium text-gray-100">
                    <%= message.body %>
                  </span>
                </div>
              </div>
              <input
                :if={@current_user}
                id="chat-input"
                placeholder="Send a message"
                disabled={@current_user == nil}
                class="mt-2 bg-gray-950 h-[30px] text-white focus:outline-none focus:ring-purple-400 block w-full min-w-0 rounded-md sm:text-sm ring-1 ring-gray-600 px-2"
              />
              <a
                :if={!@current_user}
                href={Algora.Github.authorize_url()}
                class="mt-2 w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-purple-600 hover:bg-purple-500 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-purple-400"
              >
                Sign in to chat
              </a>
            </div>
          </div>
        </div>
      </div>
    </aside>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, socket, layout: false, temporary_assigns: [subtitles: [], messages: []]}
  end

  def handle_event("show", %{"video_id" => video_id}, socket) do
    subtitles = Library.list_subtitles(%Library.Video{id: video_id})

    data = %{}

    {:ok, encoded_subtitles} =
      subtitles
      |> Enum.map(&%{id: &1.id, start: &1.start, end: &1.end, body: &1.body})
      |> Jason.encode(pretty: true)

    types = %{subtitles: :string}
    params = %{subtitles: encoded_subtitles}

    changeset =
      {data, types}
      |> Ecto.Changeset.cast(params, Map.keys(types))

    video = Library.get_video!(video_id)

    socket =
      socket
      |> assign(video: video)
      |> assign(subtitles: subtitles)
      |> assign(messages: Chat.list_messages(video))
      |> assign_form(changeset)
      |> push_event("join_chat", %{id: video_id})

    {:noreply, socket}
  end

  def handle_event("save", %{"data" => %{"subtitles" => subtitles}, "save" => save_type}, socket) do
    save(save_type, subtitles)
    {:noreply, socket}
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

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset, as: :data))
  end
end
