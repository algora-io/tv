defmodule AlgoraWeb.TagsComponent do
  use AlgoraWeb, :live_component

  def render(assigns) do
    # to fix the nil issue i faced
    assigns = assign_new(assigns, :input_value, fn  -> ""  end)
    ~H"""
      <div class="tag-input-container">
      <div class="flex flex-col">
        <label class="pb-2 font-bold">Channel tags</label>
        <input type="text"
          id={@id}
          name={@name}
          value={@input_value}
          phx-keydown="add_tag"
          phx-key="Enter"
          phx-target={@myself}
          placeholder="Type a tag and press Enter"
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

  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  def handle_event("add_tag", %{"key" => "Enter", "value" => value}, socket) do
    tag = String.trim(value)
    if tag !== "" and tag not in socket.assigns.tags do
      updated_tags = socket.assigns.tags ++ [tag]
      {:noreply, assign(socket, tags: updated_tags, input_value: "")}
    else
      {:noreply, socket}
    end
  end

  def handle_event("remove_tag", %{"tag" => tag}, socket) do
    updated_tags = List.delete(socket.assigns.tags, tag)
    {:noreply, assign(socket, tags: updated_tags)}
  end
end
