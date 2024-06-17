defmodule Algora.HLS.EtsHelper do
  @moduledoc false

  alias Algora.Room

  @rooms_to_tables :rooms_to_tables

  @recent_partial_key :recent_partial
  @manifest_key :manifest

  @delta_recent_partial_key :delta_recent_partial
  @delta_manifest_key :delta_manifest

  @hls_folder_path :rooms_to_folder_paths

  @type partial :: {non_neg_integer(), non_neg_integer()}

  ###
  ### ROOM MANAGMENT
  ###

  @spec add_room(Room.id()) :: {:ok, reference()} | {:error, :already_exists}
  def add_room(room_id) do
    if room_exists?(room_id) do
      {:error, :already_exists}
    else
      # Ets is public because ll-storage can't delete table.
      # If we change that storage can be protected
      #
      # Read concurrency can cause performance degradation when the common access pattern
      # is a few read operations interleaved with a few write operations repeatedly.
      # When used on a larger scale it should be carefully tested
      table = :ets.new(:hls_storage, [:public, read_concurrency: true])

      :ets.insert(@rooms_to_tables, {room_id, table})
      {:ok, table}
    end
  end

  @spec remove_room(Room.id()) :: :ok | {:error, String.t()}
  def remove_room(room_id) do
    case :ets.lookup(@rooms_to_tables, room_id) do
      [{^room_id, _table}] ->
        # The table will be automatically removed when the HLS component process dies.
        :ets.delete(@rooms_to_tables, room_id)
        :ok

      _empty ->
        {:error, "Room: #{room_id} doesn't exist"}
    end
  end

  ###
  ### ETS CONTENT MANAGMENT
  ###

  @spec update_manifest(:ets.table(), String.t()) :: true
  def update_manifest(table, manifest) do
    :ets.insert(table, {@manifest_key, manifest})
  end

  @spec update_delta_manifest(:ets.table(), String.t()) :: true
  def update_delta_manifest(table, delta_manifest) do
    :ets.insert(table, {@delta_manifest_key, delta_manifest})
  end

  @spec update_recent_partial(:ets.table(), partial()) :: true
  def update_recent_partial(table, partial) do
    :ets.insert(table, {@recent_partial_key, partial})
  end

  @spec update_delta_recent_partial(:ets.table(), partial()) :: true
  def update_delta_recent_partial(table, partial) do
    :ets.insert(table, {@delta_recent_partial_key, partial})
  end

  @spec add_partial(:ets.table(), binary(), String.t()) :: true
  def add_partial(table, partial, filename) do
    :ets.insert(table, {filename, partial})
  end

  @spec delete_partial(:ets.table(), String.t()) :: true
  def delete_partial(table, filename) do
    :ets.delete(table, filename)
  end

  @spec add_hls_folder_path(Room.id(), String.t()) :: true
  def add_hls_folder_path(room_id, path) do
    :ets.insert(@hls_folder_path, {room_id, path})
  end

  @spec delete_hls_folder_path(Room.id()) :: true
  def delete_hls_folder_path(room_id) do
    :ets.delete(@hls_folder_path, room_id)
  end

  ###
  ### ETS GETTERS
  ###

  @spec get_partial(Room.id(), String.t()) ::
          {:ok, binary()} | {:error, atom()}
  def get_partial(room_id, filename) do
    get_from_ets(room_id, filename)
  end

  @spec get_recent_partial(Room.id()) ::
          {:ok, {non_neg_integer(), non_neg_integer()}} | {:error, atom()}
  def get_recent_partial(room_id) do
    get_from_ets(room_id, @recent_partial_key)
  end

  @spec get_delta_recent_partial(Room.id()) ::
          {:ok, {non_neg_integer(), non_neg_integer()}} | {:error, atom()}
  def get_delta_recent_partial(room_id) do
    get_from_ets(room_id, @delta_recent_partial_key)
  end

  @spec get_manifest(Room.id()) :: {:ok, String.t()} | {:error, atom()}
  def get_manifest(room_id) do
    get_from_ets(room_id, @manifest_key)
  end

  @spec get_delta_manifest(Room.id()) :: {:ok, String.t()} | {:error, atom()}
  def get_delta_manifest(room_id) do
    get_from_ets(room_id, @delta_manifest_key)
  end

  @spec get_hls_folder_path(Room.id()) :: {:ok, String.t()} | {:error, :room_not_found}
  def get_hls_folder_path(room_id) do
    get_path(room_id)
  end

  ###
  ### PRIVATE FUNCTIONS
  ###

  defp get_from_ets(room_id, key) do
    with {:ok, table} <- get_table(room_id) do
      lookup_ets(table, key)
    end
  end

  defp lookup_ets(table, key) do
    lookup_helper(table, key, :file_not_found)
  end

  defp get_table(room_id) do
    lookup_helper(@rooms_to_tables, room_id, :room_not_found)
  end

  defp get_path(room_id) do
    lookup_helper(@hls_folder_path, room_id, :room_not_found)
  end

  defp lookup_helper(table, key, error) do
    case :ets.lookup(table, key) do
      [{^key, val}] -> {:ok, val}
      [] -> {:error, error}
    end
  end

  defp room_exists?(room_id) do
    :ets.lookup(@rooms_to_tables, room_id) != []
  end
end
