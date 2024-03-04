defmodule AlgoraWeb.SubtitleLive.FormComponent do
  use AlgoraWeb, :live_component

  alias Algora.Library

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage subtitle records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="subtitle-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:body]} type="text" label="Body" />
        <.input field={@form[:start]} type="number" label="Start" step="any" />
        <.input field={@form[:end]} type="number" label="End" step="any" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Subtitle</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{subtitle: subtitle} = assigns, socket) do
    changeset = Library.change_subtitle(subtitle)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"subtitle" => subtitle_params}, socket) do
    changeset =
      socket.assigns.subtitle
      |> Library.change_subtitle(subtitle_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"subtitle" => subtitle_params}, socket) do
    save_subtitle(socket, socket.assigns.action, subtitle_params)
  end

  defp save_subtitle(socket, :edit, subtitle_params) do
    case Library.update_subtitle(socket.assigns.subtitle, subtitle_params) do
      {:ok, subtitle} ->
        notify_parent({:saved, subtitle})

        {:noreply,
         socket
         |> put_flash(:info, "Subtitle updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_subtitle(socket, :new, subtitle_params) do
    case Library.create_subtitle(subtitle_params) do
      {:ok, subtitle} ->
        notify_parent({:saved, subtitle})

        {:noreply,
         socket
         |> put_flash(:info, "Subtitle created successfully")
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
