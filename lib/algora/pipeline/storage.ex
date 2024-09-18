defmodule Algora.Pipeline.Storage do
  @moduledoc false

  @behaviour Membrane.HTTPAdaptiveStream.Storage

  require Membrane.Logger
  alias Algora.Pipeline.HLS.LLController
  alias Algora.Pipeline.Storage.Thumbnails
  alias Algora.Library

  @enforce_keys [:directory, :video]
  defstruct @enforce_keys ++
              [
                partial_sn: 0,
                segment_sn: 0,
                partials_in_ets: [],
                video_header: <<>>,
                video_segment: <<>>,
                setup_completed?: false
              ]

  @type partial_ets_key :: String.t()
  @type sequence_number :: non_neg_integer()
  @type partial_in_ets ::
          {{segment_sn :: sequence_number(), partial_sn :: sequence_number()}, partial_ets_key()}

  @type t :: %__MODULE__{
          directory: Path.t(),
          video: Library.Video.t(),
          partial_sn: sequence_number(),
          segment_sn: sequence_number(),
          partials_in_ets: [partial_in_ets()],
          video_header: <<>>,
          video_segment: <<>>,
          setup_completed?: boolean()
        }

  @ets_cached_duration_in_segments 4
  @delta_manifest_suffix "_delta.m3u8"

  @impl true
  def init(state) do
    state
  end

  @impl true
  def store(parent_id, name, content, metadata, context, state) do
    case context do
      %{mode: :binary, type: :segment} ->
        store_content(parent_id, name, content, metadata, context, state)

      %{mode: :binary, type: :partial_segment} ->
        cache_partial_segment(parent_id, name, content, metadata, context, state)

      %{mode: :binary, type: :header} ->
        store_content(parent_id, name, content, metadata, context, state)

      %{mode: :text, type: :manifest} ->
        cache_manifest(name, content, state)
        store_content(parent_id, name, content, metadata, context, state)
    end
  end

  @impl true
  def remove(_parent_id, name, _ctx, %__MODULE__{directory: directory} = state) do
    result =
      directory
      |> Path.join(name)
      |> File.rm()

    {result, state}
  end

  defp cache_partial_segment(
         parent_id,
         name,
         contents,
         %{sequence_number: sequence_number, partial_name: partial_name} = metadata,
         ctx,
         state
       ) do
    state =
      process_contents(parent_id, name, contents, metadata, ctx, state)
      |> update_sequence_numbers(sequence_number)
      |> add_partial_to_ets(partial_name, contents)

    {:ok, state}
  end

  defp cache_manifest(
         filename,
         content,
         %__MODULE__{video: video} = state
       ) do
    broadcast!(video.uuid, [LLController, :write_to_file, [video.uuid, filename, content]])

    unless filename == "index.m3u8" do
      add_manifest_to_ets(filename, content, state)
      send_update(filename, state)
    end

    {:ok, state}
  end

  defp add_manifest_to_ets(filename, manifest, %{video: video}) do
    broadcast!(video.uuid, [
      LLController,
      if(String.ends_with?(filename, @delta_manifest_suffix),
        do: :update_delta_manifest,
        else: :update_manifest
      ),
      [video.uuid, manifest]
    ])
  end

  defp add_partial_to_ets(
         %{
           partials_in_ets: partials_in_ets,
           segment_sn: segment_sn,
           partial_sn: partial_sn,
           video: video
         } = state,
         partial_name,
         content
       ) do
    broadcast!(video.uuid, [LLController, :add_partial, [video.uuid, content, partial_name]])

    partial = {segment_sn, partial_sn}
    %{state | partials_in_ets: [{partial, partial_name} | partials_in_ets]}
  end

  defp remove_partials_from_ets(
         %{
           partials_in_ets: partials_in_ets,
           segment_sn: curr_segment_sn,
           video: video
         } = state
       ) do
    {partials_in_ets, partial_to_be_removed} =
      Enum.split_with(partials_in_ets, fn {{segment_sn, _partial_sn}, _partial_name} ->
        segment_sn + @ets_cached_duration_in_segments > curr_segment_sn
      end)

    Enum.each(partial_to_be_removed, fn {_sn, partial_name} ->
      broadcast!(video.uuid, [LLController, :delete_partial, [video.uuid, partial_name]])
    end)

    %{state | partials_in_ets: partials_in_ets}
  end

  defp broadcast!(video_uuid, msg), do: LLController.broadcast!(video_uuid, msg)

  defp send_update(filename, %{
         video: video,
         segment_sn: segment_sn,
         partial_sn: partial_sn
       }) do
    manifest =
      if(String.ends_with?(filename, @delta_manifest_suffix),
        do: :delta_manifest,
        else: :manifest
      )

    partial = {segment_sn, partial_sn}

    broadcast!(video.uuid, [LLController, :update_recent_partial, [video.uuid, partial, manifest]])
  end

  defp update_sequence_numbers(
         %{segment_sn: segment_sn, partial_sn: partial_sn} = state,
         new_partial_sn
       ) do
    new_segment? = new_partial_sn < partial_sn

    if new_segment? do
      state = %{state | segment_sn: segment_sn + 1, partial_sn: new_partial_sn}
      # If there is a new segment we want to remove partials that are too old from ets
      remove_partials_from_ets(state)
    else
      %{state | partial_sn: new_partial_sn}
    end
  end

  def store_content(
        parent_id,
        name,
        contents,
        metadata,
        ctx,
        state
      ) do
    path = "#{state.video.uuid}/#{name}"
    state = process_contents(parent_id, name, contents, metadata, ctx, state)

    Task.Supervisor.start_child(Algora.TaskSupervisor, fn ->
      with {t, {:ok, _}} <-
             :timer.tc(&Algora.Storage.upload/3, [contents, path, upload_opts(ctx)]) do
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
      else
        err ->
          Membrane.Logger.error("Failed to upload #{path}: #{err}")
      end
    end)

    {:ok, state}
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

  defp process_contents(
         :video,
         _name,
         contents,
         _metadata,
         %{type: :header, mode: :binary},
         state
       ) do
    %{state | video_header: contents}
  end

  defp process_contents(
         :video,
         _name,
         contents,
         %{independent?: true},
         %{type: :partial_segment, mode: :binary},
         %{setup_completed?: false, video: video, video_header: video_header} = state
       ) do
    Task.Supervisor.start_child(Algora.TaskSupervisor, fn ->
      Thumbnails.store_thumbnail(video, video_header, contents)
    end)

    %{state | setup_completed?: true, video_segment: contents}
  end

  defp process_contents(
         :video,
         _name,
         contents,
         _metadata,
         %{type: :segment, mode: :binary},
         state
       ) do
    %{state | video_segment: contents}
  end

  defp process_contents(_parent_id, _name, _contents, _metadata, _ctx, state) do
    state
  end
end
