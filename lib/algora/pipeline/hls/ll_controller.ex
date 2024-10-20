defmodule Algora.Pipeline.HLS.LLController do
  @moduledoc false

  use GenServer
  use Bunch.Access

  alias Algora.Pipeline.HLS.EtsHelper
  alias Algora.Library.Video
  alias Algora.Admin

  @delta_manifest_suffix "_delta.m3u8"

  @enforce_keys [:video_uuid, :directory, :video_pid]
  defstruct @enforce_keys ++
              [
                table: nil,
                preload_hints: [],
                manifest: %{waiting_pids: %{}, last_partial: nil},
                delta_manifest: %{waiting_pids: %{}, last_partial: nil}
              ]

  @type segment_sn :: non_neg_integer()
  @type partial_sn :: non_neg_integer()
  @type partial :: {segment_sn(), partial_sn()}
  @type status :: %{waiting_pids: %{partial() => [pid()]}, last_partial: partial() | nil}

  @type t :: %__MODULE__{
          video_uuid: Video.uuid(),
          directory: Path.t(),
          video_pid: pid(),
          table: :ets.table() | nil,
          manifest: status(),
          delta_manifest: status(),
          preload_hints: [pid()]
        }

  ###
  ### HLS Controller API
  ###

  # FIXME: Opportunity for Improvement
  #
  # During stress test simulations involving 500 clients (at a rate of 1 Gb/s)
  # it has been observed that RAM usage can surge up to 1 GB due solely to HLS requests.
  # This spike is primarily caused by the current strategy of reading files individually for each request, rather than caching them in memory.
  #
  # Recommendation:
  # To mitigate this issue, consider implementing a cache storage mechanism that maintains the last six segments.
  # This way, whenever possible, these segments are retrieved from the cache instead of being repeatedly read from the file.

  @doc """
  Handles requests: playlists (regular hls), master playlist, headers, regular segments
  """
  @spec handle_file_request(Video.uuid(), String.t()) :: {:ok, binary()} | {:error, atom()}
  def handle_file_request(video_uuid, filename) do
    with {:ok, video_path} <- EtsHelper.get_hls_folder_path(video_uuid) do
      file_path = video_path |> Path.join(filename) |> Path.expand()

      if inside_directory?(file_path, Path.expand(video_path)),
        do: File.read(file_path),
        else: {:error, :invalid_path}
    end
  end

  @doc """
  Handles ll-hls partial requests
  """
  @spec handle_partial_request(Video.uuid(), String.t()) ::
          {:ok, binary()} | {:error, atom()}
  def handle_partial_request(video_uuid, filename) do
    with {:ok, partial} <- EtsHelper.get_partial(video_uuid, filename) do
      {:ok, partial}
    else
      {:error, :file_not_found} ->
        case preload_hint?(video_uuid, filename) do
          {:ok, true} ->
            wait_for_partial_ready(video_uuid, filename)

          _other ->
            {:error, :file_not_found}
        end

      error ->
        error
    end
  end

  @doc """
  Handles manifest requests with specific partial requested (ll-hls)
  """
  @spec handle_manifest_request(Video.uuid(), partial()) ::
          {:ok, String.t()} | {:error, atom()}
  def handle_manifest_request(video_uuid, partial) do
    with {:ok, last_partial} <- EtsHelper.get_recent_partial(video_uuid) do
      unless partial_ready?(partial, last_partial) do
        wait_for_manifest_ready(video_uuid, partial, :manifest)
      end

      EtsHelper.get_manifest(video_uuid)
    end
  end

  @doc """
  Handles delta manifest requests with specific partial requested (ll-hls)
  """
  @spec handle_delta_manifest_request(Video.uuid(), partial()) ::
          {:ok, String.t()} | {:error, atom()}
  def handle_delta_manifest_request(video_uuid, partial) do
    with {:ok, last_partial} <- EtsHelper.get_delta_recent_partial(video_uuid) do
      unless partial_ready?(partial, last_partial) do
        wait_for_manifest_ready(video_uuid, partial, :delta_manifest)
      end

      EtsHelper.get_delta_manifest(video_uuid)
    end
  end

  ###
  ### STORAGE API
  ###

  @spec update_manifest(Video.uuid(), String.t()) :: :ok
  def update_manifest(video_uuid, manifest) do
    GenServer.cast(registry_id(video_uuid), {:update_manifest, manifest})
  end

  @spec update_delta_manifest(Video.uuid(), String.t()) :: :ok
  def update_delta_manifest(video_uuid, delta_manifest) do
    GenServer.cast(registry_id(video_uuid), {:update_delta_manifest, delta_manifest})
  end

  @spec update_recent_partial(Video.uuid(), partial(), :manifest | :delta_manifest) :: :ok
  def update_recent_partial(video_uuid, last_partial, manifest) do
    GenServer.cast(registry_id(video_uuid), {:update_recent_partial, last_partial, manifest})
  end

  @spec add_partial(Video.uuid(), binary(), String.t()) :: :ok
  def add_partial(video_uuid, partial, filename) do
    GenServer.cast(registry_id(video_uuid), {:add_partial, partial, filename})
  end

  @spec delete_partial(Video.uuid(), String.t()) :: :ok
  def delete_partial(video_uuid, filename) do
    GenServer.cast(registry_id(video_uuid), {:delete_partial, filename})
  end

  def write_to_file(video_uuid, filename, content) do
    GenServer.cast(registry_id(video_uuid), {:write_to_file, filename, content})
  end

  def cache_manifest(video_uuid, filename, content, {segment_sn, partial_sn}) do
    GenServer.cast(
      registry_id(video_uuid),
      {:cache_manifest, filename, content, {segment_sn, partial_sn}}
    )
  end

  ###
  ### MANAGEMENT API
  ###

  def start(video_uuid, directory) do
    # Request handler monitors the video process.
    # This ensures that it will be killed if video crashes.
    # In case of different use of this module it has to be refactored
    GenServer.start(
      __MODULE__,
      %{video_uuid: video_uuid, directory: directory, video_pid: self()},
      name: registry_id(video_uuid)
    )
  end

  def stop(video_uuid) do
    GenServer.cast(registry_id(video_uuid), :shutdown)
  end

  @impl true
  def init(%{video_uuid: video_uuid, directory: directory, video_pid: video_pid}) do
    # TODO:
    # Process.monitor(video_pid)

    File.mkdir_p!(directory)
    EtsHelper.add_hls_folder_path(video_uuid, directory)

    with {:ok, table} <- EtsHelper.add_video(video_uuid) do
      {:ok,
       %__MODULE__{
         video_uuid: video_uuid,
         directory: directory,
         video_pid: video_pid,
         table: table
       }}
    else
      {:error, :already_exists} ->
        raise("Can't create ets table - another table already exists for video #{video_uuid}")
    end
  end

  @impl true
  def handle_cast({:partial_ready?, partial, from, manifest}, state) do
    state =
      state
      |> Map.fetch!(manifest)
      |> handle_partial_ready?(partial, from)
      |> then(&Map.put(state, manifest, &1))

    {:noreply, state}
  end

  @impl true
  def handle_cast({:preload_hint, video_uuid, filename, from}, state) do
    with {:ok, _partial} <- EtsHelper.get_partial(video_uuid, filename) do
      send(from, :preload_hint_ready)
      {:noreply, state}
    else
      {:error, _reason} ->
        {:noreply, %{state | preload_hints: [from | state.preload_hints]}}
    end
  end

  @impl true
  def handle_cast({:update_manifest, manifest}, %{table: table} = state) do
    EtsHelper.update_manifest(table, manifest)
    {:noreply, state}
  end

  @impl true
  def handle_cast({:update_delta_manifest, delta_manifest}, %{table: table} = state) do
    EtsHelper.update_delta_manifest(table, delta_manifest)
    {:noreply, state}
  end

  @impl true
  def handle_cast(
        {:update_recent_partial, last_partial, manifest},
        %{preload_hints: preload_hints, table: table} = state
      ) do
    case manifest do
      :manifest -> EtsHelper.update_recent_partial(table, last_partial)
      :delta_manifest -> EtsHelper.update_delta_recent_partial(table, last_partial)
    end

    status = Map.fetch!(state, manifest)

    state =
      state
      |> Map.put(manifest, update_and_notify_manifest_ready(status, last_partial))
      |> Map.put(:preload_hints, update_and_notify_preload_hint_ready(preload_hints))

    {:noreply, state}
  end

  @impl true
  def handle_cast({:add_partial, partial, filename}, %{table: table} = state) do
    EtsHelper.add_partial(table, partial, filename)
    {:noreply, state}
  end

  @impl true
  def handle_cast({:delete_partial, filename}, %{table: table} = state) do
    EtsHelper.delete_partial(table, filename)
    {:noreply, state}
  end

  def handle_cast({:write_to_file, filename, content}, %{directory: directory} = state) do
    directory
    |> Path.join(filename)
    |> File.write(content)

    {:noreply, state}
  end

  def handle_cast({:cache_manifest, filename, content, {segment_sn, partial_sn}}, state) do
    manifest_type =
      if String.ends_with?(filename, @delta_manifest_suffix) do
        :delta_manifest
      else
        :manifest
      end

    write_to_file(state.video_uuid, filename, content)

    unless filename == "index.m3u8" do
      case manifest_type do
        :delta_manifest -> update_delta_manifest(state.video_uuid, content)
        _ -> update_manifest(state.video_uuid, content)
      end

      update_recent_partial(state.video_uuid, {segment_sn, partial_sn}, manifest_type)
    end

    {:noreply, state}
  end

  @impl true
  def handle_cast({:apply, [module, function, args]}, state) do
    apply(module, function, args)
    {:noreply, state}
  end

  @impl true
  def handle_cast(:shutdown, state) do
    {:stop, :normal, state}
  end

  @impl true
  def terminate(_reason, %{video_uuid: video_uuid}) do
    EtsHelper.remove_video(video_uuid)
  end

  # TODO:
  # @impl true
  # def handle_info({:DOWN, _ref, :process, pid, _reason}, %{video_pid: pid} = state) do
  #   {:stop, :normal, state}
  # end

  ###
  ### PRIVATE FUNCTIONS
  ###

  defp wait_for_manifest_ready(video_uuid, partial, manifest) do
    GenServer.cast(registry_id(video_uuid), {:partial_ready?, partial, self(), manifest})

    receive do
      :manifest_ready ->
        :ok
    end
  end

  defp wait_for_partial_ready(video_uuid, filename) do
    GenServer.cast(registry_id(video_uuid), {:preload_hint, video_uuid, filename, self()})

    receive do
      :preload_hint_ready ->
        EtsHelper.get_partial(video_uuid, filename)
    end
  end

  defp update_and_notify_preload_hint_ready(preload_hints) do
    send_preload_hint_ready(preload_hints)
    []
  end

  defp update_and_notify_manifest_ready(%{waiting_pids: waiting_pids} = status, last_partial) do
    partials_ready =
      waiting_pids
      |> Map.keys()
      |> Enum.filter(fn partial -> partial_ready?(partial, last_partial) end)

    partials_ready
    |> Enum.flat_map(fn partial -> Map.fetch!(waiting_pids, partial) end)
    |> then(&send_partial_ready(&1))

    waiting_pids = Map.drop(waiting_pids, partials_ready)

    %{status | waiting_pids: waiting_pids, last_partial: last_partial}
  end

  defp handle_partial_ready?(status, partial, from) do
    if partial_ready?(partial, status.last_partial) do
      send(from, :manifest_ready)
      status
    else
      waiting_pids =
        Map.update(status.waiting_pids, partial, [from], fn pids_list ->
          [from | pids_list]
        end)

      %{status | waiting_pids: waiting_pids}
    end
  end

  defp preload_hint?(video_uuid, filename) do
    partial_sn = get_partial_sn(filename)

    with {:ok, recent_partial_sn} <- EtsHelper.get_recent_partial(video_uuid) do
      {:ok, check_if_preload_hint(partial_sn, recent_partial_sn)}
    end
  end

  defp check_if_preload_hint({segment_sn, partial_sn}, {recent_segment_sn, recent_partial_sn}) do
    cond do
      segment_sn - recent_segment_sn == 1 and partial_sn == 0 -> true
      segment_sn == recent_segment_sn and (partial_sn - recent_partial_sn) in [0, 1] -> true
      true -> false
    end
  end

  defp check_if_preload_hint(_partial_sn, _recent_partial_sn) do
    require Logger

    Logger.warning("Unable to parse partial segment filename")
    false
  end

  # Filename example: muxed_segment_32_g2QABXZpZGVv_5_part.m4s
  defp get_partial_sn(filename) do
    filename
    |> String.split("_")
    |> Enum.filter(fn s -> match?({_integer, ""}, Integer.parse(s)) end)
    |> Enum.map(fn sn -> String.to_integer(sn) end)
    |> List.to_tuple()
  end

  def registry_id(video_uuid), do: {:via, Registry, {Algora.LLControllerRegistry, video_uuid}}

  defp send_partial_ready(waiting_pids) do
    Enum.each(waiting_pids, fn pid -> send(pid, :manifest_ready) end)
  end

  defp send_preload_hint_ready(waiting_pids) do
    Enum.each(waiting_pids, fn pid -> send(pid, :preload_hint_ready) end)
  end

  defp partial_ready?(_partial, nil) do
    false
  end

  defp partial_ready?({segment_sn, partial_sn}, {last_segment_sn, last_partial_sn}) do
    cond do
      last_segment_sn > segment_sn -> true
      last_segment_sn < segment_sn -> false
      true -> last_partial_sn >= partial_sn
    end
  end

  defp inside_directory?(path, directory) do
    relative_path = Path.relative_to(path, directory)
    relative_path != path and relative_path != "."
  end

  def broadcast!(video_uuid, [_module, _function, _args] = msg) do
    for node <- Admin.nodes() do
      :rpc.cast(node, Algora.Pipeline.HLS.LLController, :apply, [video_uuid, msg])
    end
  end

  def apply(video_uuid, msg) do
    GenServer.cast(registry_id(video_uuid), {:apply, msg})
  end
end
