defmodule AlgoraWeb.VideoProducerLive do
  use AlgoraWeb, :live_view
  alias Algora.{Repo, Admin, Library, Clipper}
  alias Algora.Library.Video
  alias AlgoraWeb.PlayerComponent
  require Logger

  @impl true
  def render(assigns) do
      ~H"""
      <div class="max-w-3xl mx-auto pt-2 pb-6 px-4 sm:px-6 space-y-6">
        <div class="space-y-6 bg-white/5 rounded-lg p-6 ring-1 ring-white/15">
          <.header>
            Clip Editor
            <:subtitle>
              Create clips from your livestreams
            </:subtitle>
          </.header>

          <.simple_form for={@form} phx-change="update_form" phx-submit="create_video">
            <.input
              field={@form[:livestream_id]}
              type="select"
              label="Select Livestream"
              options={Enum.map(@livestreams, &{&1.title, &1.id})}
              value={@selected_livestream && @selected_livestream.id}
              prompt="Choose a livestream"
            />
            <.input field={@form[:title]} type="text" label="Title" />
            <.input field={@form[:description]} type="textarea" label="Description" />

            <.button type="button" phx-click="add_clip">Add New Clip</.button>

            <div class="space-y-4">
              <%= for {clip, index} <- Enum.with_index(@clips) do %>
                <div class="bg-white/5 rounded-lg p-4 ring-1 ring-white/15">
                  <div class="flex items-center justify-between mb-2">
                    <h3 class="text-lg font-semibold">Clip <%= index + 1 %></h3>
                    <.button type="button" phx-click="remove_clip" phx-value-index={index} class="text-red-500">
                      <Heroicons.x_mark solid class="h-5 w-5" />
                    </.button>
                  </div>
                  <div class="grid grid-cols-2 gap-4">
                    <.input type="text" name={"video_production[clips][#{index}][clip_from]"} value={clip.clip_from} label="Start Time" placeholder="HH:MM:SS" phx-debounce="300"/>
                    <.input type="text" name={"video_production[clips][#{index}][clip_to]"} value={clip.clip_to} label="End Time" placeholder="HH:MM:SS" phx-debounce="300"/>
                  </div>
                  <div class="flex justify-between mt-4">
                    <.button type="button" phx-click="move_clip_up" phx-value-index={index} disabled={index == 0}>Move Up</.button>
                    <.button type="button" phx-click="move_clip_down" phx-value-index={index} disabled={index == length(@clips) - 1}>Move Down</.button>
                    <.button type="button" phx-click="preview_clip" phx-value-index={index}>Preview Clip</.button>
                  </div>
                </div>
              <% end %>
            </div>

            <:actions>
              <.button type="submit" disabled={@processing}>Create Video</.button>
            </:actions>
          </.simple_form>

          <%= if @selected_livestream do %>
            <div class="mt-4 p-4 bg-white/5 rounded-lg ring-1 ring-white/15">
              <h3 class="text-lg font-semibold mb-2">Video Preview</h3>
              <div id="preview-player-container" phx-update="ignore">
                <.live_component
                  module={PlayerComponent}
                  id="preview-player"
                  video={@selected_livestream}
                  current_time={@preview_clip && @preview_clip.start || 0}
                  end_time={@preview_clip && @preview_clip.end || nil}
                  current_user={@current_user}
                />
              </div>
            </div>
          <% end %>

          <%= if @processing do %>
            <div class="mt-4 p-4 bg-white/5 rounded-lg ring-1 ring-white/15">
              <p class="font-semibold"><%= @progress.stage %></p>
              <div class="w-full bg-gray-200 rounded-full h-2.5 dark:bg-gray-700 mt-2">
                <div class="bg-blue-600 h-2.5 rounded-full" style={"width: #{@progress.progress * 100}%"}></div>
              </div>
            </div>
          <% end %>
        </div>
      </div>
      """
    end

  @impl true
  def mount(_params, _session, socket) do
    channel = Library.get_channel!(socket.assigns.current_user)
    livestreams = Library.list_channel_videos(channel)
    # livestreams = Library.list_videos()
    changeset = change_video_production()
    default_video = List.first(livestreams)
    send_update(PlayerComponent,
      id: "preview-player",
      video: default_video,
      current_time: 0,
    )

    {:ok,
     socket
     |> assign(
       livestreams: livestreams,
       selected_livestream: default_video,
       clips: [],
       processing: false,
       progress: %{stage: nil, current: 0, total: 0},
       preview_clip: nil
     )
     |> assign_form(changeset)}
  end

  def handle_event("update_form", %{"video_production" => params}, socket) do
    IO.puts("update_form params: #{inspect(params)}")

    socket = if params["livestream_id"] && params["livestream_id"] != to_string(socket.assigns.selected_livestream.id) do
      new_livestream = Enum.find(socket.assigns.livestreams, &(&1.id == String.to_integer(params["livestream_id"])))
      IO.puts("new_livestream: title: #{new_livestream.title} id: #{new_livestream.id}")

      if new_livestream do
        send_update(PlayerComponent,
          id: "preview-player",
          video: new_livestream,
          current_time: 0,
          end_time: nil,
          current_user: socket.assigns.current_user
        )

        socket
          |> assign(selected_livestream: new_livestream)
          |> assign(preview_clip: nil)
          |> assign(clips: [])  # Clear the clips
      else
        socket
      end
    else
      socket
    end

    # Update clips only if the livestream hasn't changed
    updated_clips = if params["livestream_id"] == to_string(socket.assigns.selected_livestream.id) do
      update_clips_from_params(params["clips"] || %{})
    else
      []
    end

    IO.puts("updated clips: #{inspect(updated_clips)}")

    changeset = change_video_production(params)

    socket = socket
      |> assign(clips: updated_clips)
      |> assign_form(changeset)

    IO.puts("update_form AFTER selected_video title:#{socket.assigns.selected_livestream.title} id: #{socket.assigns.selected_livestream.id}")

    {:noreply, socket}
  end

  defp update_clips_from_params(clips_params) do
      IO.puts("update_clips_from_params clips_params: #{inspect(clips_params)}")
      clips_params
      |> Enum.sort_by(fn {key, _} -> key end)
      |> Enum.map(fn {_, clip} ->
        %{clip_from: clip["clip_from"], clip_to: clip["clip_to"]}
      end)
  end

  defp change_video_production(attrs \\ %{}) do
    types = %{
      livestream_id: :integer,
      title: :string,
      description: :string,
      clips: {:array, :map}
    }

    {%{}, types}
    |> Ecto.Changeset.cast(attrs, Map.keys(types))
    |> Ecto.Changeset.validate_required([:livestream_id, :title])
    |> Ecto.Changeset.validate_length(:title, min: 3, max: 100)
    |> Ecto.Changeset.validate_length(:description, max: 500)
    |> validate_clips()
  end

  defp validate_clips(changeset) do
      clips = Ecto.Changeset.get_field(changeset, :clips) || []

      clips_with_index = Enum.with_index(clips)
      clips_changeset =
        Enum.reduce(clips_with_index, changeset, fn {clip, index}, acc ->
          Ecto.Changeset.put_change(acc, :"clip_#{index}", clip)
        end)

      Enum.reduce(clips_with_index, clips_changeset, fn {_clip, index}, acc ->
        acc
        |> Ecto.Changeset.validate_required(:"clip_#{index}")
        |> validate_clip_times(:"clip_#{index}")
      end)
    end

  defp validate_clip_times(changeset, field) do
      clip = Ecto.Changeset.get_field(changeset, field)

      with {:ok, start_time} <- parse_time(clip["start"]),
           {:ok, end_time} <- parse_time(clip["end"]) do
        if Time.compare(start_time, end_time) == :lt do
          changeset
        else
          Ecto.Changeset.add_error(changeset, field, "End time must be after start time")
        end
      else
        :error ->
          Ecto.Changeset.add_error(changeset, field, "Invalid time format. Use HH:MM:SS")
      end
    end

  defp parse_time(time_string) do
    with [hours, minutes, seconds] <- String.split(time_string, ":", parts: 3),
          {hours, ""} <- Integer.parse(hours),
          {minutes, ""} <- Integer.parse(minutes),
          {seconds, ""} <- Integer.parse(seconds) do
      Time.new(hours, minutes, seconds)
    else
      _ -> :error
    end
  end

  @impl true
  def handle_event("validate", %{"video_production" => params}, socket) do
    changeset =
      params
      |> change_video_production()
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  @impl true
  def handle_event("add_clip", _, socket) do
    clips = socket.assigns.clips ++ [%{clip_from: "", clip_to: ""}]
    {:noreply, assign(socket, clips: clips)}
  end

  @impl true
  def handle_event("remove_clip", %{"index" => index}, socket) do
    index = String.to_integer(index)
    clips = List.delete_at(socket.assigns.clips, index)
    {:noreply, assign(socket, clips: clips)}
  end

  @impl true
  def handle_event("move_clip_up", %{"index" => index}, socket) do
    index = String.to_integer(index)
    clips = socket.assigns.clips

    if index > 0 do
      updated_clips = List.update_at(clips, index - 1, fn _ -> Enum.at(clips, index) end)
      updated_clips = List.update_at(updated_clips, index, fn _ -> Enum.at(clips, index - 1) end)
      {:noreply, assign(socket, clips: updated_clips)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("move_clip_down", %{"index" => index}, socket) do
    index = String.to_integer(index)
    clips = socket.assigns.clips

    if index < length(clips) - 1 do
      updated_clips = List.update_at(clips, index + 1, fn _ -> Enum.at(clips, index) end)
      updated_clips = List.update_at(updated_clips, index, fn _ -> Enum.at(clips, index + 1) end)
      {:noreply, assign(socket, clips: updated_clips)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("preview_clip", %{"index" => index}, socket) do
    index = String.to_integer(index)
    video = socket.assigns.selected_livestream
    IO.puts("preview_clip selected_video title:#{video.title} id: #{video.id}")
    clip = Enum.at(socket.assigns.clips, index)
    IO.puts("clip: #{inspect(clip)}")

    if clip && clip.clip_from != "" && clip.clip_to != "" && video do
      start = Library.from_hhmmss(clip.clip_from)
      end_time = Library.from_hhmmss(clip.clip_to)

      IO.puts("current_time: #{start} end_time: #{end_time}")
      send_update(PlayerComponent,
        id: "preview-player",
        video: video,
        current_time: start,
        end_time: end_time,
        title: "Previewing Clip #{index + 1}",
        current_user: socket.assigns.current_user
      )

      {:noreply, assign(socket, preview_clip: %{start: start, end: end_time})}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("select_livestream", %{"video_production" => %{"livestream_id" => id}}, socket) do
    selected_livestream = Enum.find(socket.assigns.livestreams, &(&1.id == String.to_integer(id)))

    if selected_livestream do
      send_update(PlayerComponent, id: "preview-player", video: selected_livestream, current_time: 0, end_time: nil, current_user: socket.assigns.current_user)
      {:noreply, assign(socket, selected_livestream: selected_livestream, preview_clip: nil)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:progress_update, progress}, socket) do
    {:noreply, assign(socket, progress: progress)}
  end

  @impl true
  def handle_info({:processing_complete, video}, socket) do
    {:noreply, socket
      |> put_flash(:info, "Video created successfully!")
      |> assign(processing: false, progress: nil)
      |> push_redirect(to: ~p"/#{video.channel_handle}/#{video.id}")}
  end

  @impl true
  def handle_info({PlayerComponent, {:time_update, current_time}}, socket) do
    if socket.assigns.preview_clip && current_time >= socket.assigns.preview_clip.end do
      send_update(PlayerComponent, id: "preview-player", command: :pause)
    end
    {:noreply, socket}
  end

  @impl true
  def handle_event("create_video", %{"video_production" => params}, socket) do
    case create_video(params, socket) do
      {:ok, video, updated_socket} ->
        if video.channel_handle && video.id do
          {:noreply,
           updated_socket
           |> assign(processing: false)
           |> push_redirect(to: ~p"/#{video.channel_handle}/#{video.id}")}
        else
          Logger.error("Invalid video data: channel_handle or id is nil. Video: #{inspect(video)}")
          {:noreply,
           updated_socket
           |> assign(processing: false)
           |> put_flash(:error, "An error occurred while creating the video. Please try again.")}
        end

      {:error, %Ecto.Changeset{} = changeset, _socket} ->
        {:noreply, assign_form(socket, changeset)}

      {:error, reason, updated_socket} ->
        Logger.error("Error creating video: #{inspect(reason)}")
        {:noreply,
         updated_socket
         |> assign(processing: false)
         |> put_flash(:error, "An error occurred: #{inspect(reason)}")}
    end
  end

  defp create_video(params, socket) do
    clips = params["clips"] || %{}
    video = socket.assigns.selected_livestream
    current_user = socket.assigns.current_user

    socket = put_flash(socket, :info, "Creating combined clip")
    Process.sleep(100) # Give time for the flash to be rendered

    case Clipper.create_combined_local_clips(video, clips) do
      {:ok, combined_clip_path} ->
        socket = put_flash(socket, :info, "Initializing video")
        Process.sleep(100) # Give time for the flash to be rendered

        # Create a Phoenix.LiveView.UploadEntry struct
        upload_entry = %Phoenix.LiveView.UploadEntry{
          client_name: Path.basename(combined_clip_path),
          client_size: File.stat!(combined_clip_path).size,
          client_type: "video/mp4"
        }

        # Initialize the new video using init_mp4!
        new_video = Library.init_mp4!(upload_entry, combined_clip_path, current_user)

        # Update the video with additional information
        {:ok, updated_video} = Library.update_video(new_video, %{
          title: params["title"] || "New Video",
          description: params["description"],
          visibility: :unlisted
        })

        socket = put_flash(socket, :info, "Processing video")
        Process.sleep(100) # Give time for the flash to be rendered

        # Use transmux_to_hls to upload, process, and generate thumbnail
        processed_video = Library.transmux_to_hls(updated_video, fn progress ->
          send(self(), {:progress_update, progress})
        end)

        # Clean up temporary file
        File.rm(combined_clip_path)

        socket = put_flash(socket, :info, "Video created successfully!")
        {:ok, processed_video, socket}

      {:error, reason} ->
        Logger.error("Failed to create combined clip: #{inspect(reason)}")
        socket = put_flash(socket, :error, "Failed to create combined clip: #{inspect(reason)}")
        {:error, reason, socket}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset, as: "video_production"))
  end
end
