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
        <div class="flex flex-col md:flex-row gap-8 justify-between">
          <div class="w-full space-y-8">
            <.input field={@form[:title]} type="text" label="Title" />
            <.input field={@form[:description]} type="textarea" label="Description" rows={3} />
          </div>
          <div class="shrink-0">
            <label for="show_title" class="block text-sm font-semibold leading-6 text-gray-100 mb-2">
              Cover image
            </label>
            <div id="show_image" phx-drop-target={@uploads.cover_image.ref} class="relative">
              <.live_file_input
                upload={@uploads.cover_image}
                class="absolute inset-0 opacity-0 cursor-pointer"
              />
              <img src={@show.image_url} class="w-[200px] rounded-lg" />
            </div>
          </div>
        </div>
        <div class="relative">
          <div class="absolute text-sm start-0 flex items-center ps-3 top-10 mt-px pointer-events-none text-gray-400">
            tv.algora.io/shows/
          </div>
          <.input field={@form[:slug]} type="text" label="URL" class="ps-[8.25rem]" />
        </div>
        <.input field={@form[:scheduled_for]} type="datetime-local" label="Date (UTC)" />
        <%!-- <.input field={@form[:image_url]} type="text" label="Image URL" /> --%>
        <%= for err <- upload_errors(@uploads.cover_image) do %>
          <p class="alert alert-danger"><%= error_to_string(err) %></p>
        <% end %>
        <:actions>
          <.button phx-disable-with="Saving...">Save</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def mount(socket) do
    {:ok,
     socket
     |> assign(:uploaded_files, [])
     |> allow_upload(:cover_image,
       accept: accept(),
       max_file_size: max_file_size() * 1_000_000,
       max_entries: 1,
       auto_upload: true,
       progress: &handle_progress/3
     )}
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

  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :cover_image, ref)}
  end

  defp handle_progress(:cover_image, entry, socket) do
    if entry.done? do
      show =
        consume_uploaded_entry(socket, entry, fn %{path: path} = _meta ->
          remote_path = "shows/#{socket.assigns.show.id}/cover/#{System.os_time(:second)}"

          {:ok, _} =
            Algora.Storage.upload_from_filename(path, remote_path, fn _ -> nil end,
              content_type: "image/jpeg"
            )

          bucket = Algora.config([:buckets, :media])
          %{scheme: scheme, host: host} = Application.fetch_env!(:ex_aws, :s3) |> Enum.into(%{})

          Shows.update_show(socket.assigns.show, %{
            image_url: "#{scheme}#{host}/#{bucket}/#{remote_path}"
          })
        end)

      notify_parent({:saved, show})

      {:noreply, socket |> assign(:show, show)}
    else
      {:noreply, socket}
    end
  end

  defp save_show(socket, :edit, show_params) do
    case Shows.update_show(socket.assigns.show, show_params) do
      {:ok, show} ->
        notify_parent({:saved, show})

        {:noreply,
         socket
         |> put_flash(:info, "Show updated successfully")
         |> push_patch(to: ~p"/shows/#{show.slug}")}

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
         |> push_patch(to: ~p"/shows/#{show.slug}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp error_to_string(:too_large) do
    "Only images up to #{max_file_size()} MB are allowed."
  end

  defp error_to_string(:not_accepted) do
    "Uploaded file is not a valid image. Only #{accept() |> Enum.intersperse(", ") |> Enum.join()} files are allowed."
  end

  defp max_file_size, do: 10
  defp accept, do: ~w(.png .jpg .jpeg .gif)

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
