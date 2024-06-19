defmodule Algora.HLS.LLStorage do
  @moduledoc false

  @behaviour Membrane.HTTPAdaptiveStream.Storage

  require Membrane.Logger
  alias Algora.HLS.{EtsHelper, LLController}
  alias Algora.Library

  @pubsub Algora.PubSub

  @enforce_keys [:directory, :video_uuid]
  defstruct @enforce_keys ++
              [
                partial_sn: 0,
                segment_sn: 0,
                partials_in_ets: [],
                table: nil,
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
          video_uuid: Library.Video.uuid(),
          table: :ets.table() | nil,
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
  def init(%__MODULE__{directory: directory, video_uuid: video_uuid}) do
    with {:ok, table} <- EtsHelper.add_video(video_uuid) do
      %__MODULE__{video_uuid: video_uuid, table: table, directory: directory}
    else
      {:error, :already_exists} ->
        raise("Can't create ets table - another table already exists for video #{video_uuid}")
    end
  end

  @impl true
  def store(parent_id, name, content, metadata, context, state) do
    case context do
      %{mode: :binary, type: :segment} ->
        store_regular(parent_id, name, content, metadata, context, state)

      %{mode: :binary, type: :partial_segment} ->
        store_partial_segment(name, content, metadata, state)

      %{mode: :binary, type: :header} ->
        store_regular(parent_id, name, content, metadata, context, state)

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

  defp add_manifest_to_ets(filename, manifest, %{table: table, video_uuid: video_uuid}) do
    fun =
      if String.ends_with?(filename, @delta_manifest_suffix) do
        :update_delta_manifest
      else
        :update_manifest
      end

    broadcast!(video_uuid, [EtsHelper, fun, [table, manifest]])
  end

  defp add_partial_to_ets(
         %{
           table: table,
           partials_in_ets: partials_in_ets,
           segment_sn: segment_sn,
           partial_sn: partial_sn,
           video_uuid: video_uuid
         } = state,
         partial_name,
         content
       ) do
    broadcast!(video_uuid, [EtsHelper, :add_partial, [table, content, partial_name]])

    partial = {segment_sn, partial_sn}
    %{state | partials_in_ets: [{partial, partial_name} | partials_in_ets]}
  end

  defp remove_partials_from_ets(
         %{
           partials_in_ets: partials_in_ets,
           segment_sn: curr_segment_sn,
           table: table,
           video_uuid: video_uuid
         } = state
       ) do
    {partials_in_ets, partial_to_be_removed} =
      Enum.split_with(partials_in_ets, fn {{segment_sn, _partial_sn}, _partial_name} ->
        segment_sn + @ets_cached_duration_in_segments > curr_segment_sn
      end)

    Enum.each(partial_to_be_removed, fn {_sn, partial_name} ->
      broadcast!(video_uuid, [EtsHelper, :delete_partial, [table, partial_name]])
    end)

    %{state | partials_in_ets: partials_in_ets}
  end

  defp broadcast!(video_uuid, msg), do: LLController.broadcast!(video_uuid, msg)

  defp partial_update_fun(filename) do
    if String.ends_with?(filename, @delta_manifest_suffix) do
      :update_delta_recent_partial
    else
      :update_recent_partial
    end
  end

  defp send_update(filename, %{
         video_uuid: video_uuid,
         table: table,
         segment_sn: segment_sn,
         partial_sn: partial_sn
       }) do
    fun = partial_update_fun(filename)
    broadcast!(video_uuid, [EtsHelper, fun, [table, {segment_sn, partial_sn}]])
    broadcast!(video_uuid, [LLController, fun, [video_uuid, {segment_sn, partial_sn}]])
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

  ## ---------------------------------------

  def store_regular(
        parent_id,
        name,
        contents,
        metadata,
        ctx,
        state
      ) do
    path = "#{state.video_uuid}/#{name}"

    with {t, {:ok, _}} <- :timer.tc(&upload/3, [contents, path, upload_opts(ctx)]),
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

  def endpoint_url do
    %{scheme: scheme, host: host} = Application.fetch_env!(:ex_aws, :s3) |> Enum.into(%{})
    "#{scheme}#{host}"
  end

  def upload_regions do
    [System.get_env("FLY_REGION") || "fra", "sjc", "fra"]
    |> Enum.uniq()
    |> Enum.join(",")
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

  def upload_to_bucket(contents, remote_path, bucket, opts \\ []) do
    op = Algora.config([:buckets, bucket]) |> ExAws.S3.put_object(remote_path, contents, opts)
    # op = %{op | headers: op.headers |> Map.merge(%{"x-tigris-regions" => upload_regions()})}
    ExAws.request(op, [])
  end

  def upload_from_filename_to_bucket(
        local_path,
        remote_path,
        bucket,
        cb \\ fn _ -> nil end,
        opts \\ []
      ) do
    %{size: size} = File.stat!(local_path)

    chunk_size = 5 * 1024 * 1024

    ExAws.S3.Upload.stream_file(local_path, [{:chunk_size, chunk_size}])
    |> Stream.map(fn chunk ->
      cb.(%{stage: :persisting, done: chunk_size, total: size})
      chunk
    end)
    |> ExAws.S3.upload(Algora.config([:buckets, bucket]), remote_path, opts)
    |> ExAws.request([])
  end

  def upload(contents, remote_path, opts \\ []) do
    upload_to_bucket(contents, remote_path, :media, opts)
  end

  def upload_from_filename(local_path, remote_path, cb \\ fn _ -> nil end, opts \\ []) do
    upload_from_filename_to_bucket(
      local_path,
      remote_path,
      :media,
      cb,
      opts
    )
  end

  def update_object!(bucket, object, opts) do
    bucket = Algora.config([:buckets, bucket])

    with {:ok, %{body: body}} <- ExAws.S3.get_object(bucket, object) |> ExAws.request(),
         {:ok, res} <- ExAws.S3.put_object(bucket, object, body, opts) |> ExAws.request() do
      res
    else
      err -> err
    end
  end

  defp broadcast_thumbnails_generated!(video) do
    Phoenix.PubSub.broadcast!(
      @pubsub,
      Library.topic_livestreams(),
      {__MODULE__, %Library.Events.ThumbnailsGenerated{video: video}}
    )
  end
end
