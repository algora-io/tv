defmodule Algora.HLS.RequestHandler do
  @moduledoc false

  use GenServer
  use Bunch.Access

  alias Algora.Utils.PathValidation
  alias Algora.HLS.EtsHelper
  alias Algora.Room

  @enforce_keys [:room_id, :room_pid]
  defstruct @enforce_keys ++
              [
                preload_hints: [],
                manifest: %{waiting_pids: %{}, last_partial: nil},
                delta_manifest: %{waiting_pids: %{}, last_partial: nil}
              ]

  @type segment_sn :: non_neg_integer()
  @type partial_sn :: non_neg_integer()
  @type partial :: {segment_sn(), partial_sn()}
  @type status :: %{waiting_pids: %{partial() => [pid()]}, last_partial: partial() | nil}

  @type t :: %__MODULE__{
          room_id: Room.id(),
          room_pid: pid(),
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
  @spec handle_file_request(Room.id(), String.t()) :: {:ok, binary()} | {:error, atom()}
  def handle_file_request(room_id, filename) do
    with {:ok, room_path} <- EtsHelper.get_hls_folder_path(room_id) do
      file_path = room_path |> Path.join(filename) |> Path.expand()

      if PathValidation.inside_directory?(file_path, Path.expand(room_path)),
        do: File.read(file_path),
        else: {:error, :invalid_path}
    end
  end

  @doc """
  Handles ll-hls partial requests
  """
  @spec handle_partial_request(Room.id(), String.t()) ::
          {:ok, binary()} | {:error, atom()}
  def handle_partial_request(room_id, filename) do
    with {:ok, partial} <- EtsHelper.get_partial(room_id, filename) do
      {:ok, partial}
    else
      {:error, :file_not_found} ->
        case preload_hint?(room_id, filename) do
          {:ok, true} ->
            wait_for_partial_ready(room_id, filename)

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
  @spec handle_manifest_request(Room.id(), partial()) ::
          {:ok, String.t()} | {:error, atom()}
  def handle_manifest_request(room_id, partial) do
    with {:ok, last_partial} <- EtsHelper.get_recent_partial(room_id) do
      unless partial_ready?(partial, last_partial) do
        wait_for_manifest_ready(room_id, partial, :manifest)
      end

      EtsHelper.get_manifest(room_id)
    end
  end

  @doc """
  Handles delta manifest requests with specific partial requested (ll-hls)
  """
  @spec handle_delta_manifest_request(Room.id(), partial()) ::
          {:ok, String.t()} | {:error, atom()}
  def handle_delta_manifest_request(room_id, partial) do
    with {:ok, last_partial} <- EtsHelper.get_delta_recent_partial(room_id) do
      unless partial_ready?(partial, last_partial) do
        wait_for_manifest_ready(room_id, partial, :delta_manifest)
      end

      EtsHelper.get_delta_manifest(room_id)
    end
  end

  ###
  ### STORAGE API
  ###

  @spec update_recent_partial(Room.id(), partial()) :: :ok
  def update_recent_partial(room_id, partial) do
    GenServer.cast(registry_id(room_id), {:update_recent_partial, partial, :manifest})
  end

  @spec update_delta_recent_partial(Room.id(), partial()) :: :ok
  def update_delta_recent_partial(room_id, partial) do
    GenServer.cast(registry_id(room_id), {:update_recent_partial, partial, :delta_manifest})
  end

  ###
  ### MANAGMENT API
  ###

  def start(room_id) do
    # Request handler monitors the room process.
    # This ensures that it will be killed if room crashes.
    # In case of different use of this module it has to be refactored
    GenServer.start(__MODULE__, %{room_id: room_id, room_pid: self()}, name: registry_id(room_id))
  end

  def stop(room_id) do
    GenServer.cast(registry_id(room_id), :shutdown)
  end

  @impl true
  def init(%{room_id: room_id, room_pid: room_pid}) do
    Process.monitor(room_pid)
    {:ok, %__MODULE__{room_id: room_id, room_pid: room_pid}}
  end

  @impl true
  def handle_cast(
        {:update_recent_partial, last_partial, manifest},
        %{preload_hints: preload_hints} = state
      ) do
    status = Map.fetch!(state, manifest)

    state =
      state
      |> Map.put(manifest, update_and_notify_manifest_ready(status, last_partial))
      |> Map.put(:preload_hints, update_and_notify_preload_hint_ready(preload_hints))

    {:noreply, state}
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
  def handle_cast({:preload_hint, room_id, filename, from}, state) do
    with {:ok, _partial} <- EtsHelper.get_partial(room_id, filename) do
      send(from, :preload_hint_ready)
      {:noreply, state}
    else
      {:error, _reason} ->
        {:noreply, %{state | preload_hints: [from | state.preload_hints]}}
    end
  end

  @impl true
  def handle_cast(:shutdown, state) do
    {:stop, :normal, state}
  end

  @impl true
  def terminate(_reason, %{room_id: room_id}) do
    EtsHelper.remove_room(room_id)
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, pid, _reason}, %{room_pid: pid} = state) do
    {:stop, :normal, state}
  end

  ###
  ### PRIVATE FUNCTIONS
  ###

  defp wait_for_manifest_ready(room_id, partial, manifest) do
    GenServer.cast(registry_id(room_id), {:partial_ready?, partial, self(), manifest})

    receive do
      :manifest_ready ->
        :ok
    end
  end

  defp wait_for_partial_ready(room_id, filename) do
    GenServer.cast(registry_id(room_id), {:preload_hint, room_id, filename, self()})

    receive do
      :preload_hint_ready ->
        EtsHelper.get_partial(room_id, filename)
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

  defp preload_hint?(room_id, filename) do
    partial_sn = get_partial_sn(filename)

    with {:ok, recent_partial_sn} <- EtsHelper.get_recent_partial(room_id) do
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

  defp registry_id(room_id), do: {:via, Registry, {Algora.RequestHandlerRegistry, room_id}}

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
end
