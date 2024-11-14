defmodule Algora.Pipeline.HLS.LLController do
  @moduledoc false

  use GenServer
  use Bunch.Access

  alias Algora.Pipeline.HLS.EtsHelper
  alias Algora.Library.Video
  alias Algora.Admin

  @enforce_keys [:video_uuid, :directory, :video_pid]
  defstruct @enforce_keys ++
              [
                table: nil,
                preload_hints: %{},
                manifest: %{},
                delta_manifest: %{}
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
          manifest: %{ String.t() => status() },
          delta_manifest: %{ String.t() => status() },
          preload_hints: %{String.t() => [pid()]}
        }

  @default_status %{waiting_pids: %{}, last_partial: nil}
  @segment_suffix_regex ~r/(_\d*_part)?\.m4s$/

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
  @spec handle_manifest_request(Video.uuid(), partial(), String.t()) ::
          {:ok, String.t()} | {:error, atom()}
  def handle_manifest_request(video_uuid, partial, filename) do
    with {:ok, last_partial} <- EtsHelper.get_recent_partial(video_uuid, filename) do
      unless partial_ready?(partial, last_partial) do
        wait_for_manifest_ready(video_uuid, partial, :manifest, filename)
      end

      EtsHelper.get_manifest(video_uuid, filename)
    end
  end

  @doc """
  Handles delta manifest requests with specific partial requested (ll-hls)
  """
  @spec handle_delta_manifest_request(Video.uuid(), partial(), String.t()) ::
          {:ok, String.t()} | {:error, atom()}
  def handle_delta_manifest_request(video_uuid, partial, filename) do
    with {:ok, last_partial} <- EtsHelper.get_delta_recent_partial(video_uuid, filename) do
      unless partial_ready?(partial, last_partial) do
        wait_for_manifest_ready(video_uuid, partial, :delta_manifest, filename)
      end

      EtsHelper.get_delta_manifest(video_uuid, filename)
    end
  end

  ###
  ### STORAGE API
  ###

  @spec update_manifest(Video.uuid(), String.t(), String.t()) :: :ok
  def update_manifest(video_uuid, manifest, filename) do
    GenServer.cast(registry_id(video_uuid), {:update_manifest, manifest, filename})
  end

  @spec update_delta_manifest(Video.uuid(), String.t(), String.t()) :: :ok
  def update_delta_manifest(video_uuid, delta_manifest, filename) do
    GenServer.cast(registry_id(video_uuid), {:update_delta_manifest, delta_manifest, filename})
  end

  @spec update_recent_partial(Video.uuid(), partial(), :manifest | :delta_manifest, String.t()) :: :ok
  def update_recent_partial(video_uuid, last_partial, manifest, filename) do
    GenServer.cast(registry_id(video_uuid), {:update_recent_partial, last_partial, manifest, filename})
  end

  @spec add_partial(Video.uuid(), binary(), binary(), String.t()) :: :ok
  def add_partial(video_uuid, segment, partial, filename) do
    GenServer.cast(registry_id(video_uuid), {:add_partial, segment, partial, filename})
  end

  @spec delete_partial(Video.uuid(), String.t()) :: :ok
  def delete_partial(video_uuid, filename) do
    GenServer.cast(registry_id(video_uuid), {:delete_partial, filename})
  end

  def write_to_file(video_uuid, filename, content) do
    GenServer.cast(registry_id(video_uuid), {:write_to_file, filename, content})
  end

  # Filename example: muxed_segment_32_g2QABXZpZGVv_5_part.m4s
  def get_manifest_name(segment_name) do
    segment_name
    |> String.replace(@segment_suffix_regex, "")
    |> String.split("_")
    |> Enum.drop_while(fn(s) -> !match?({_integer, ""}, Integer.parse(s)) end)
    |> Enum.drop(1)
    |> Enum.join("_")
    |> then(fn
      ("") -> {:error, :unknown_segment_name_format}
      (name) -> {:ok, "#{name}.m3u8"}
    end)
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
  def handle_cast({:partial_ready?, partial, from, manifest, filename}, state) do
    manifests = Map.get(state, manifest)
    state = manifests
      |> Map.fetch!(filename)
      |> handle_partial_ready?(partial, from)
      |> then(&Map.put(manifests, filename, &1))
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
        preload_hints = if {:ok, manifest_name} = get_manifest_name(filename) do
          hints_for_file = state
            |> Map.get(:preload_hints, %{})
            |> Map.get(filename, [])
          Map.put(state.preload_hints, manifest_name, [from | hints_for_file])
        else
          state.preload_hints
        end

      {:noreply, %{ state | preload_hints: preload_hints }}
    end
  end

  @impl true
  def handle_cast({:update_manifest, manifest, filename}, %{table: table} = state) do
    EtsHelper.update_manifest(table, manifest, filename)
    {:noreply, state}
  end

  @impl true
  def handle_cast({:update_delta_manifest, delta_manifest, filename}, %{table: table} = state) do
    EtsHelper.update_delta_manifest(table, delta_manifest, filename)
    {:noreply, state}
  end

  @impl true
  def handle_cast(
        {:update_recent_partial, last_partial, manifest, filename},
        %{preload_hints: preload_hints, table: table} = state
      ) do

    case manifest do
      :manifest -> EtsHelper.update_recent_partial(table, last_partial, filename)
      :delta_manifest -> EtsHelper.update_delta_recent_partial(table, last_partial, filename)
    end

    manifests = Map.fetch!(state, manifest)

    new_manifests = manifests
      |> Map.get(filename, @default_status)
      |> update_and_notify_manifest_ready(last_partial)
      |> then(&Map.put(manifests, filename, &1))

    new_preload_hints = preload_hints
      |> Map.get(filename, [])
      |> update_and_notify_preload_hint_ready()
      |> then(&Map.put(preload_hints, filename, &1))

    state =
      state
      |> Map.put(manifest, new_manifests)
      |> Map.put(:preload_hints, new_preload_hints)

    {:noreply, state}
  end

  @impl true
  def handle_cast({:add_partial, partial, _segment_name, partial_name}, %{table: table} = state) do
    EtsHelper.add_partial(table, partial, partial_name)
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

  defp wait_for_manifest_ready(video_uuid, partial, manifest, filename) do
    GenServer.cast(registry_id(video_uuid), {:partial_ready?, partial, self(), manifest, filename})

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

    with {:ok, manifest_name} <- get_manifest_name(filename),
         {:ok, recent_partial_sn} <- EtsHelper.get_recent_partial(video_uuid, manifest_name) do
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
