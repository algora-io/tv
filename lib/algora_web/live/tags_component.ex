defmodule AlgoraWeb.TagsComponent do
  use AlgoraWeb, :live_component

  def update(assigns, socket) do
    {:ok, assign(socket, id: assigns.id, name: assigns.name, tags: assigns.tags)}
  end

  def render(assigns) do
    ~H"""
    <div class="tag-input-container" id={"tag-input-container-#{@id}"} phx-hook="ChannelTagInput">
      <div class="flex flex-col">
        <label class="pb-2 font-bold">Channel tags</label>
        <input type="text"
          id={"#{@id}-input"}
          name={@name}
          phx-keydown="key_pressed"
          phx-target={@myself}
          placeholder="Type a tag and press the spacebar to add it"
          class="flex-grow px-3 py-2 bg-gray-950 focus:border-gray-600 shadow-sm focus:ring-gray-600 placeholder-slate-100 block w-full rounded-md sm:text-sm focus:ring-1"
        />
      </div>
      <div class="flex flex-wrap gap-2 mt-2">
        <%= for tag <- @tags do %>
          <span class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-gray-950 text-white border border-gray-600">
            <%= tag %>
            <button type="button" phx-click="remove_tag" phx-value-tag={tag} phx-target={@myself} class="ml-1 danger-400 hover:text-blue-600">
              &times;
            </button>
          </span>
        <% end %>
      </div>
    </div>
    """
  end

  def handle_event("key_pressed", %{"key" => " ", "value" => value}, socket) do
    add_tag(socket, value)
  end

  def handle_event("key_pressed", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("remove_tag", %{"tag" => tag}, socket) do
    updated_tags = List.delete(socket.assigns.tags, tag)
    send(self(), {:update_tags, updated_tags})
    {:noreply, assign(socket, tags: updated_tags)}
  end

  defp add_tag(socket, value) do
    tag = String.trim(value)
    current_tags = socket.assigns.tags

    if tag !== "" and tag not in current_tags do
      updated_tags = current_tags ++ [tag]
      send(self(), {:update_tags, updated_tags})
      {:noreply,
       socket
       |> assign(tags: updated_tags)
       |> push_event("tag_added", %{})}
    else
      {:noreply, socket}
    end
  end
end
