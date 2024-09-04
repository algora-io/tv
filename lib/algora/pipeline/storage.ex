defmodule Algora.Pipeline.Storage do
  @behaviour Membrane.HTTPAdaptiveStream.Storage

  require Membrane.Logger
  alias Algora.Library

  @pubsub Algora.PubSub

  @enforce_keys [:video]
  defstruct @enforce_keys ++ [video_header: <<>>, video_segment: <<>>, setup_completed?: false]

  @type t :: %__MODULE__{
          video: Library.Video.t(),
          video_header: <<>>,
          video_segment: <<>>,
          setup_completed?: boolean()
        }

  @impl true
  def init(%__MODULE__{} = config), do: config

  @impl true
  def store(
        parent_id,
        name,
        contents,
        metadata,
        ctx,
        %{video: video} = state
      ) do
    path = "#{video.uuid}/#{name}"

    with {t, {:ok, _}} <- :timer.tc(&Algora.Storage.upload/3, [contents, path, upload_opts(ctx)]),
         {:ok, state} <- process_contents(parent_id, name, contents, metadata, ctx, state) do
      size = :erlang.byte_size(contents) / 1_000
      time = t / 1_000

      region = System.get_env("FLY_REGION") || "local"

      case ctx do
        %{type: :segment} ->
          Membrane.Logger.info(
            "Uploaded #{Float.round(size, 1)} kB in #{Float.round(time, 1)} ms (#{Float.round(size / time, 1)} MB/s, #{region})"
          )

        _ ->
          nil
      end

      {:ok, state}
    else
      {:error, reason} = err ->
        Membrane.Logger.error("Failed to upload #{path}: #{reason}")
        {err, state}
    end
  end

  defp upload_opts(%{type: :manifest} = _ctx) do
    [
      content_type: "application/x-mpegURL",
      cache_control: "no-cache, no-store, private"
    ]
  end

  defp upload_opts(%{type: :segment} = _ctx) do
    [content_type: "video/mp4"]
  end

  defp upload_opts(_ctx), do: []

  @impl true
  def remove(_parent_id, _name, _ctx, state) do
    {{:error, :not_implemented}, state}
  end

  defp process_contents(
         :video,
         _name,
         contents,
         _metadata,
         %{type: :header, mode: :binary},
         state
       ) do
    {:ok, %{state | video_header: contents}}
  end

  defp process_contents(
         :video,
         _name,
         contents,
         _metadata,
         %{type: :segment, mode: :binary},
         %{setup_completed?: false, video: video, video_header: video_header} = state
       ) do
    Task.Supervisor.start_child(Algora.TaskSupervisor, fn ->
      with {:ok, video} <- Library.store_thumbnail(video, video_header <> contents),
           {:ok, video} <- Library.store_og_image(video) do
        # HACK: this shouldn't be necessary
        # atm we need it because initially the video does not have the user field set
        video = Library.get_video!(video.id)

        broadcast_thumbnails_generated!(video)
      else
        _ ->
          Membrane.Logger.error("Could not generate thumbnails for video #{video.id}")
      end
    end)

    {:ok, %{state | setup_completed?: true, video_segment: contents}}
  end

  defp process_contents(
         :video,
         _name,
         contents,
         _metadata,
         %{type: :segment, mode: :binary},
         state
       ) do
    {:ok, %{state | video_segment: contents}}
  end

  defp process_contents(_parent_id, _name, _contents, _metadata, _ctx, state) do
    {:ok, state}
  end

  defp broadcast!(topic, msg) do
    Phoenix.PubSub.broadcast!(@pubsub, topic, {__MODULE__, msg})
  end

  defp broadcast_thumbnails_generated!(video) do
    broadcast!(Library.topic_livestreams(), %Library.Events.ThumbnailsGenerated{video: video})
  end
end
