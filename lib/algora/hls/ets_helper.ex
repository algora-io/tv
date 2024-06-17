defmodule Algora.HLS.EtsHelper do
  @moduledoc false

  alias Algora.Library.Video

  @videos_to_tables :videos_to_tables

  @recent_partial_key :recent_partial
  @manifest_key :manifest

  @delta_recent_partial_key :delta_recent_partial
  @delta_manifest_key :delta_manifest

  @hls_folder_path :videos_to_folder_paths

  @type partial :: {non_neg_integer(), non_neg_integer()}

  ###
  ### VIDEO MANAGMENT
  ###

  @spec add_video(Video.uuid()) :: {:ok, reference()} | {:error, :already_exists}
  def add_video(video_uuid) do
    if video_exists?(video_uuid) do
      {:error, :already_exists}
    else
      # Ets is public because ll-storage can't delete table.
      # If we change that storage can be protected
      #
      # Read concurrency can cause performance degradation when the common access pattern
      # is a few read operations interleaved with a few write operations repeatedly.
      # When used on a larger scale it should be carefully tested
      table = :ets.new(:hls_storage, [:public, read_concurrency: true])

      :ets.insert(@videos_to_tables, {video_uuid, table})
      {:ok, table}
    end
  end

  @spec remove_video(Video.uuid()) :: :ok | {:error, String.t()}
  def remove_video(video_uuid) do
    case :ets.lookup(@videos_to_tables, video_uuid) do
      [{^video_uuid, _table}] ->
        # The table will be automatically removed when the HLS component process dies.
        :ets.delete(@videos_to_tables, video_uuid)
        :ok

      _empty ->
        {:error, "Video: #{video_uuid} doesn't exist"}
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

  @spec add_hls_folder_path(Video.uuid(), String.t()) :: true
  def add_hls_folder_path(video_uuid, path) do
    :ets.insert(@hls_folder_path, {video_uuid, path})
  end

  @spec delete_hls_folder_path(Video.uuid()) :: true
  def delete_hls_folder_path(video_uuid) do
    :ets.delete(@hls_folder_path, video_uuid)
  end

  ###
  ### ETS GETTERS
  ###

  @spec get_partial(Video.uuid(), String.t()) ::
          {:ok, binary()} | {:error, atom()}
  def get_partial(video_uuid, filename) do
    get_from_ets(video_uuid, filename)
  end

  @spec get_recent_partial(Video.uuid()) ::
          {:ok, {non_neg_integer(), non_neg_integer()}} | {:error, atom()}
  def get_recent_partial(video_uuid) do
    get_from_ets(video_uuid, @recent_partial_key)
  end

  @spec get_delta_recent_partial(Video.uuid()) ::
          {:ok, {non_neg_integer(), non_neg_integer()}} | {:error, atom()}
  def get_delta_recent_partial(video_uuid) do
    get_from_ets(video_uuid, @delta_recent_partial_key)
  end

  @spec get_manifest(Video.uuid()) :: {:ok, String.t()} | {:error, atom()}
  def get_manifest(video_uuid) do
    get_from_ets(video_uuid, @manifest_key)
  end

  @spec get_delta_manifest(Video.uuid()) :: {:ok, String.t()} | {:error, atom()}
  def get_delta_manifest(video_uuid) do
    get_from_ets(video_uuid, @delta_manifest_key)
  end

  @spec get_hls_folder_path(Video.uuid()) :: {:ok, String.t()} | {:error, :video_not_found}
  def get_hls_folder_path(video_uuid) do
    get_path(video_uuid)
  end

  ###
  ### PRIVATE FUNCTIONS
  ###

  defp get_from_ets(video_uuid, key) do
    with {:ok, table} <- get_table(video_uuid) do
      lookup_ets(table, key)
    end
  end

  defp lookup_ets(table, key) do
    lookup_helper(table, key, :file_not_found)
  end

  defp get_table(video_uuid) do
    lookup_helper(@videos_to_tables, video_uuid, :video_not_found)
  end

  defp get_path(video_uuid) do
    lookup_helper(@hls_folder_path, video_uuid, :video_not_found)
  end

  defp lookup_helper(table, key, error) do
    case :ets.lookup(table, key) do
      [{^key, val}] -> {:ok, val}
      [] -> {:error, error}
    end
  end

  defp video_exists?(video_uuid) do
    :ets.lookup(@videos_to_tables, video_uuid) != []
  end
end
