defmodule AlgoraWeb.VideoProducerLive do
  use AlgoraWeb, :live_view
  alias Algora.{Repo, Admin, Library, Clipper}
  alias Algora.Library.Video
  alias AlgoraWeb.PlayerComponent
  require Logger

  @invalid_time_format "Invalid time. Use HH:MM:SS"

  @impl true
  def render(assigns) do
      ~H"""
      <div class="min-h-[90vh]">
          <div class="max-w-6xl mx-auto pt-2 pb-6 px-4 sm:px-6 space-y-6">
            <h1 class="text-lg font-semibold leading-8 text-gray-100 focus:outline-none">Clip editor</h1>
            <.simple_form for={@form} phx-change="update_form" phx-submit="create_video">
              <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div class="space-y-4">
                  <div class="relative">
                    <.input
                      field={@form[:livestream_id]}
                      type="select"
                      options={Enum.map(@livestreams, &{&1.title, &1.id})}
                      value={@selected_livestream && @selected_livestream.id}
                      prompt="Select livestream"
                      class="w-full bg-white/5 border border-white/15 rounded p-2 appearance-none"
                    />
                  </div>
                  <div class="aspect-video bg-white/5 rounded flex items-center justify-center">
                    <%= if @selected_livestream do %>
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
                    <% else %>
                      <Heroicons.play solid class="w-16 h-16" />
                    <% end %>
                  </div>
                  <.input field={@form[:title]} type="text" label="Title" class="w-full bg-white/5 border border-white/15 rounded p-2" />
                  <.input field={@form[:description]} type="textarea" label="Description" class="w-full bg-white/5 border border-white/15 rounded p-2 h-24" />
                </div>
                <div class="space-y-4 max-h-[calc(100vh-16rem)] overflow-y-auto p-2">
                <%= for {clip, index} <- Enum.with_index(@clips) do %>
                  <div class="bg-white/5 rounded-lg p-4 space-y-2 ring-1 ring-white/15 relative">
                    <div class="flex justify-between items-center">
                      <h3 class="font-semibold">Clip <%= index + 1 %></h3>
                      <button type="button" phx-click="clip_action" phx-value-action="remove"phx-value-index={index} class="absolute top-2 right-2 text-gray-400 hover:text-gray-200">
                        <Heroicons.x_mark solid class="w-5 h-5" />
                      </button>
                    </div>
                    <div class="grid grid-cols-2 gap-2">
                      <div>
                        <label class="block text-xs mb-1">From</label>
                        <.input type="text" name={"video_production[clips][#{index}][clip_from]"} value={clip.clip_from} class="w-full bg-white/5 border border-white/15 rounded p-1 text-sm" phx-debounce="300" />
                        <%= if clip.errors[:clip_from] do %>
                          <span class="text-red-500 text-xs"><%= clip.errors[:clip_from] %></span>
                        <% end %>
                      </div>
                      <div>
                        <label class="block text-xs mb-1">To</label>
                        <.input type="text" name={"video_production[clips][#{index}][clip_to]"} value={clip.clip_to} class="w-full bg-white/5 border border-white/15 rounded p-1 text-sm" phx-debounce="300" />
                        <%= if clip.errors[:clip_to] do %>
                          <span class="text-red-500 text-xs"><%= clip.errors[:clip_to] %></span>
                        <% end %>
                      </div>
                    </div>
                    <div class="flex py-2 space-x-2">
                      <.button type="button" phx-click="preview_clip" phx-value-index={index} class="flex-grow" disabled={clip.errors != %{}}>Preview Clip <%= index + 1 %></.button>
                      <div class="flex gap-2">
                        <.button type="button" phx-click="clip_action" phx-value-action="move_up"phx-value-index={index}>
                          <Heroicons.chevron_up solid class="w-4 h-4" />
                        </.button>
                        <.button type="button" phx-click="clip_action" phx-value-action="move_down" phx-value-index={index}>
                          <Heroicons.chevron_down solid class="w-4 h-4" />
                        </.button>
                      </div>
                    </div>
                  </div>
                <% end %>
                  <.button type="button" phx-click="clip_action" phx-value-action="add" phx-value-index={-1} class="w-full">+ Add new clip</.button>
                </div>
              </div>
              <:actions>
                <.button type="submit" disabled={@processing} class="w-full rounded-xl p-3 font-semibold" disabled={@processing}>
                  <%= if @processing, do: "Processing...", else: "Create video (#{total_duration(@clips)})" %>
                </.button>
              </:actions>
            </.simple_form>
            <%= if @processing do %>
              <div class="mt-4 text-center text-sm text-gray-400"><%= @progress.stage %>...</div>
              <div class="w-full bg-white/5 rounded-full h-2.5 mt-2">
                <div class="bg-blue-600 h-2.5 rounded-full" style={"width: #{@progress.progress * 100}%"}></div>
              </div>
            <% end %>
            </div>
        </div>
      """
    end

  defp total_duration(clips) do
    total_seconds = Enum.reduce(clips, 0, fn clip, acc ->
      case {clip.clip_from, clip.clip_to} do
        {"", ""} -> acc
        {from, to} when from != "" and to != "" ->
          try do
            from_seconds = Library.from_hhmmss(from)
            to_seconds = Library.from_hhmmss(to)
            if from_seconds < to_seconds do
              acc + (to_seconds - from_seconds)
            else
              acc
            end
          rescue
            ArgumentError -> acc
          end
        _ -> acc
      end
    end)

    Library.to_hhmmss(total_seconds)
  end

  @impl true
  def mount(_params, _session, socket) do
    channel = Library.get_channel!(socket.assigns.current_user)
    livestreams = Library.list_channel_videos(channel)
    changeset = change_video_production()
    default_video = List.first(livestreams)

    update_player(socket, default_video, 0)

    {:ok,
     socket
     |> assign(
       livestreams: livestreams,
       selected_livestream: default_video,
       clips: [%{clip_from: "", clip_to: "", errors: %{}}],
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
    clips_params
    |> Enum.sort_by(fn {key, _} -> key end)
    |> Enum.map(fn {_, clip} ->
      from = clip["clip_from"] || ""
      to = clip["clip_to"] || ""

      %{
        clip_from: from,
        clip_to: to,
        errors: validate_clip_times(from, to),
      }
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

  defp validate_clip_times(from, to) do
    case {parse_seconds(from), parse_seconds(to)} do
      {{:ok, from_seconds}, {:ok, to_seconds}} ->
        if from_seconds < to_seconds do
          %{}
        else
          %{clip_to: "End time must be after start time"}
        end
      {{:error, :invalid_format}, _} ->
        %{clip_from: @invalid_time_format}
      {_, {:error, :invalid_format}} ->
        %{clip_to: @invalid_time_format}
      _ ->
        %{clip_from: @invalid_time_format, clip_to: @invalid_time_format}
    end
  end

  defp parse_seconds(time_string) do
    time_string
    |> String.split(":")
    |> Enum.map(&String.to_integer/1)
    |> case do
      [ss] -> {:ok, ss}
      [mm, ss] -> {:ok, mm * 60 + ss}
      [hh, mm, ss] -> {:ok, hh * 3600 + mm * 60 + ss}
      _ -> {:error, :invalid_format}
    end
  rescue
    _ -> {:error, :invalid_format}
  end

  defp update_progress(progress) do
      normalized_progress = case progress do
        %{stage: :transmuxing, done: done, total: total} ->
          0.6 + (done / total) * 0.3
        %{stage: :persisting, done: done, total: total} ->
          0.9 + (done / total) * 0.05
        %{stage: :generating_thumbnail, done: _, total: _} ->
          0.95
        _ -> 0
      end

      %{stage: progress.stage, progress: normalized_progress}
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
  def handle_event("clip_action", %{"action" => action, "index" => index}, socket) do
    index = String.to_integer(index)
    clips = socket.assigns.clips

    updated_clips = case action do
      "add" -> clips ++ [%{clip_from: "", clip_to: "", errors: %{}}]
      "remove" -> List.delete_at(clips, index)
      "move_up" when index > 0 ->
        {clip, clips} = List.pop_at(clips, index)
        List.insert_at(clips, index - 1, clip)
      "move_down" when index < length(clips) - 1 ->
        {clip, clips} = List.pop_at(clips, index)
        List.insert_at(clips, index + 1, clip)
      _ -> clips
    end

    {:noreply, assign(socket, clips: updated_clips)}
  end

  @impl true
  def handle_event("preview_clip", %{"index" => index}, socket) do
    index = String.to_integer(index)
    clip = Enum.at(socket.assigns.clips, index)

    if clip.errors == %{} && clip.clip_to != "" && clip.clip_from != "" do
      case {parse_seconds(clip.clip_from), parse_seconds(clip.clip_to)} do
        {{:ok, start}, {:ok, end_time}} when end_time > start ->
          video = socket.assigns.selected_livestream
          update_player(socket, video, start, end_time, "Previewing Clip #{index + 1}")
          {:noreply, assign(socket, preview_clip: %{start: start, end: end_time})}
        _ ->
          {:noreply, put_flash(socket, :error, "An unexpected error occurred while previewing the clip")}
      end
    else
      {:noreply, put_flash(socket, :error, "Cannot preview an invalid clip")}
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
    {:noreply, assign(socket, progress: update_progress(progress))}
  end

  @impl true
  def handle_info({:processing_complete, video}, socket) do
    {:noreply, socket
      |> put_flash(:info, "Video created successfully!")
      |> assign(processing: false, progress: nil)
      |> push_redirect(to: ~p"/#{video.channel_handle}/#{video.id}")}
  end

  @impl true
  def handle_event("create_video", %{"video_production" => params}, socket) do
    socket = assign(socket, processing: true)
    case create_video(params, socket) do
      {:ok, video, updated_socket} ->
        if video.channel_handle && video.id do
          {:noreply,
           updated_socket
           |> assign(processing: false)
           |> put_flash(:info, "Video created successfully!")
           |> push_redirect(to: ~p"/#{video.channel_handle}/#{video.id}")}
        else
          Logger.error("Invalid video data: channel_handle or id is nil. Video: #{inspect(video)}")
          {:noreply,
           updated_socket
           |> assign(processing: false)
           |> put_flash(:error, "An error occurred while creating the video. Please try again.")}
        end

      {:error, %Ecto.Changeset{} = changeset, _socket} ->
        {:noreply, socket |> assign(processing: false) |> assign_form(changeset)}

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

    # Check for clip errors
    clip_errors = clips
    |> update_clips_from_params()
    |> Enum.flat_map(fn clip -> Map.to_list(clip.errors) end)

    if Enum.empty?(clip_errors) do
      socket = assign(socket, processing: true, progress: %{stage: "Initializing", progress: 0})

      case Clipper.create_combined_local_clips(video, clips) do
        {:ok, combined_clip_path} ->
          socket = assign(socket, progress: %{stage: "Creating combined clip", progress: 0.2})

          # Create a Phoenix.LiveView.UploadEntry struct
          upload_entry = %Phoenix.LiveView.UploadEntry{
            client_name: Path.basename(combined_clip_path),
            client_size: File.stat!(combined_clip_path).size,
            client_type: "video/mp4"
          }

          # Initialize the new video using init_mp4!
          new_video = Library.init_mp4!(upload_entry, combined_clip_path, current_user)

          socket = assign(socket, progress: %{stage: "Initializing video", progress: 0.4})

          # Update the video with additional information
          {:ok, updated_video} = Library.update_video(new_video, %{
            title: params["title"] || "New Video",
            description: params["description"],
            visibility: :unlisted
          })

          socket = assign(socket, progress: %{stage: "Processing video", progress: 0.6})

          # Use transmux_to_hls to upload, process, and generate thumbnail
          processed_video = Library.transmux_to_hls(updated_video, fn progress ->
            send(self(), {:progress_update, progress})
          end)

          # Clean up temporary file
          File.rm(combined_clip_path)

          socket = assign(socket, progress: %{stage: "Completed", progress: 1.0})
          {:ok, processed_video, socket}

        {:error, reason} ->
          Logger.error("Failed to create combined clip: #{inspect(reason)}")
          socket = assign(socket, processing: false, progress: nil)
          {:error, reason, socket}
      end
    else
      error_messages = Enum.map(clip_errors, fn {_, msg} -> msg end)
      |> Enum.join(", ")
      socket = assign(socket, processing: false, progress: nil)
      {:error, "Invalid clips: #{error_messages}", socket}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset, as: "video_production"))
  end

  defp update_player(socket, video, current_time, end_time \\ nil, title \\ nil) do
     send_update(PlayerComponent,
       id: "preview-player",
       video: video,
       current_time: current_time,
       end_time: end_time,
       title: title,
       current_user: socket.assigns.current_user
     )
   end
end
