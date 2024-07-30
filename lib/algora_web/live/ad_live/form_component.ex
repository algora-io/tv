defmodule AlgoraWeb.AdLive.FormComponent do
  use AlgoraWeb, :live_component

  alias Algora.Ads

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
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
        <.input field={@form[:verified]} type="checkbox" label="Verified" />
        <.input field={@form[:website_url]} type="text" label="Website url" />
        <.input field={@form[:composite_asset_url]} type="text" label="Composite asset url" />
        <.input field={@form[:asset_url]} type="text" label="Asset url" />
        <.input field={@form[:logo_url]} type="text" label="Logo url" />
        <.input field={@form[:qrcode_url]} type="text" label="Qrcode url" />
        <.input field={@form[:start_date]} type="datetime-local" label="Start date" />
        <.input field={@form[:end_date]} type="datetime-local" label="End date" />
        <.input field={@form[:total_budget]} type="number" label="Total budget" />
        <.input field={@form[:daily_budget]} type="number" label="Daily budget" />
        <.input
          field={@form[:tech_stack]}
          type="select"
          multiple
          label="Tech stack"
          options={[{"Option 1", "option1"}, {"Option 2", "option2"}]}
        />
        <.input
          field={@form[:status]}
          type="select"
          label="Status"
          prompt="Choose a value"
          options={Ecto.Enum.values(Algora.Ads.Ad, :status)}
        />
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
