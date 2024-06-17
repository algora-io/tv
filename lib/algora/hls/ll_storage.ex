defmodule Algora.HLS.LLStorage do
  @moduledoc false

  @behaviour Membrane.HTTPAdaptiveStream.Storage

  alias Algora.HLS.{EtsHelper, RequestHandler}
  alias Algora.Library.Video

  @enforce_keys [:directory, :video_uuid]
  defstruct @enforce_keys ++
              [partial_sn: 0, segment_sn: 0, partials_in_ets: [], table: nil]

  @type partial_ets_key :: String.t()
  @type sequence_number :: non_neg_integer()
  @type partial_in_ets ::
          {{segment_sn :: sequence_number(), partial_sn :: sequence_number()}, partial_ets_key()}

  @type t :: %__MODULE__{
          directory: Path.t(),
          video_uuid: Video.uuid(),
          table: :ets.table() | nil,
          partial_sn: sequence_number(),
          segment_sn: sequence_number(),
          partials_in_ets: [partial_in_ets()]
        }

  @ets_cached_duration_in_segments 4
  @delta_manifest_suffix "_delta.m3u8"

  @impl true
  def init(%__MODULE__{directory: directory, video_uuid: video_uuid}) do
    with {:ok, table} <- EtsHelper.add_video(video_uuid) do
      %__MODULE__{video_uuid: video_uuid, table: table, directory: directory}
    else
      {:error, :already_exists} ->
        raise("Can't create ets table - another table already exists for video #{video_uuid}")
    end
  end

  @impl true
  def store(_parent_id, name, content, metadata, context, state) do
    case context do
      %{mode: :binary, type: :segment} ->
        {:ok, state}

      %{mode: :binary, type: :partial_segment} ->
        store_partial_segment(name, content, metadata, state)

      %{mode: :binary, type: :header} ->
        store_header(name, content, state)

      %{mode: :text, type: :manifest} ->
        store_manifest(name, content, state)
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

  defp store_partial_segment(
         segment_name,
         content,
         %{sequence_number: sequence_number, partial_name: partial_name},
         %__MODULE__{directory: directory} = state
       ) do
    result = write_to_file(directory, segment_name, content, [:binary, :append])

    state =
      state
      |> update_sequence_numbers(sequence_number)
      |> add_partial_to_ets(partial_name, content)

    {result, state}
  end

  defp store_header(
         filename,
         content,
         %__MODULE__{directory: directory} = state
       ) do
    result = write_to_file(directory, filename, content, [:binary])
    {result, state}
  end

  defp store_manifest(
         filename,
         content,
         %__MODULE__{directory: directory} = state
       ) do
    result = write_to_file(directory, filename, content)

    unless filename == "index.m3u8" do
      add_manifest_to_ets(filename, content, state)
      send_update(filename, state)
    end

    {result, state}
  end

  defp add_manifest_to_ets(filename, manifest, %{table: table}) do
    if String.ends_with?(filename, @delta_manifest_suffix) do
      EtsHelper.update_delta_manifest(table, manifest)
    else
      EtsHelper.update_manifest(table, manifest)
    end
  end

  defp add_partial_to_ets(
         %{
           table: table,
           partials_in_ets: partials_in_ets,
           segment_sn: segment_sn,
           partial_sn: partial_sn
         } = state,
         partial_name,
         content
       ) do
    EtsHelper.add_partial(table, content, partial_name)

    partial = {segment_sn, partial_sn}
    %{state | partials_in_ets: [{partial, partial_name} | partials_in_ets]}
  end

  defp remove_partials_from_ets(
         %{partials_in_ets: partials_in_ets, segment_sn: curr_segment_sn, table: table} = state
       ) do
    {partials_in_ets, partial_to_be_removed} =
      Enum.split_with(partials_in_ets, fn {{segment_sn, _partial_sn}, _partial_name} ->
        segment_sn + @ets_cached_duration_in_segments > curr_segment_sn
      end)

    Enum.each(partial_to_be_removed, fn {_sn, partial_name} ->
      EtsHelper.delete_partial(table, partial_name)
    end)

    %{state | partials_in_ets: partials_in_ets}
  end

  defp send_update(filename, %{
         video_uuid: video_uuid,
         table: table,
         segment_sn: segment_sn,
         partial_sn: partial_sn
       }) do
    if String.ends_with?(filename, @delta_manifest_suffix) do
      EtsHelper.update_delta_recent_partial(table, {segment_sn, partial_sn})
      RequestHandler.update_delta_recent_partial(video_uuid, {segment_sn, partial_sn})
    else
      EtsHelper.update_recent_partial(table, {segment_sn, partial_sn})
      RequestHandler.update_recent_partial(video_uuid, {segment_sn, partial_sn})
    end
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

  defp write_to_file(directory, filename, content, write_options \\ []) do
    directory
    |> Path.join(filename)
    |> File.write(content, write_options)
  end
end
