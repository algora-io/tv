defmodule AlgoraWeb.ShowLive.FormComponent do
  use AlgoraWeb, :live_component

  alias Algora.Shows

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header class="pb-6">
        <%= @title %>
      </.header>

      <.simple_form
        for={@form}
        id="show-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:title]} type="text" label="Title" />
        <.input field={@form[:description]} type="textarea" label="Description" />
        <div class="relative">
          <div class="absolute text-sm start-0 flex items-center ps-3 top-10 mt-px pointer-events-none text-gray-400">
            tv.algora.io/shows/
          </div>
          <.input field={@form[:slug]} type="text" label="URL" class="ps-[8.25rem]" />
        </div>
        <.input field={@form[:scheduled_for]} type="datetime-local" label="Date" />
        <.input field={@form[:image_url]} type="text" label="Image URL" />
        <:actions>
          <.button phx-disable-with="Saving...">Save</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{show: show} = assigns, socket) do
    changeset = Shows.change_show(show)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"show" => show_params}, socket) do
    changeset =
      socket.assigns.show
      |> Shows.change_show(show_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"show" => show_params}, socket) do
    save_show(socket, socket.assigns.action, show_params)
  end

  defp save_show(socket, :edit, show_params) do
    case Shows.update_show(socket.assigns.show, show_params) do
      {:ok, show} ->
        notify_parent({:saved, show})

        {:noreply,
         socket
         |> put_flash(:info, "Show updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_show(socket, :new, show_params) do
    case Shows.create_show(show_params) do
      {:ok, show} ->
        notify_parent({:saved, show})

        {:noreply,
         socket
         |> put_flash(:info, "Show created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
