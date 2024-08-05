defmodule AlgoraWeb.AdLive.FormComponent do
  use AlgoraWeb, :live_component

  alias Algora.Ads

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header class="mb-8">
        <%= @title %>
        <:subtitle>Use this form to manage ad records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="ad-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <div class="relative">
          <div class="absolute text-sm start-0 flex items-center ps-3 top-10 mt-px pointer-events-none text-gray-400">
            tv.algora.io/go/
          </div>
          <.input field={@form[:slug]} type="text" label="QR Code URL" class="ps-[6.75rem]" />
        </div>
        <.input field={@form[:website_url]} type="text" label="Website URL" />
        <.input field={@form[:composite_asset_url]} type="text" label="Asset URL" />
        <.input field={@form[:border_color]} type="text" label="Border color" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Ad</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{ad: ad} = assigns, socket) do
    changeset = Ads.change_ad(ad)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"ad" => ad_params}, socket) do
    changeset =
      socket.assigns.ad
      |> Ads.change_ad(ad_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"ad" => ad_params}, socket) do
    save_ad(socket, socket.assigns.action, ad_params)
  end

  defp save_ad(socket, :edit, ad_params) do
    case Ads.update_ad(socket.assigns.ad, ad_params) do
      {:ok, ad} ->
        notify_parent({:saved, ad})

        {:noreply,
         socket
         |> put_flash(:info, "Ad updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_ad(socket, :new, ad_params) do
    case Ads.create_ad(ad_params) do
      {:ok, ad} ->
        notify_parent({:saved, ad})

        {:noreply,
         socket
         |> put_flash(:info, "Ad created successfully")
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
