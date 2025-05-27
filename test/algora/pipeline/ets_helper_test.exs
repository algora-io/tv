defmodule Algora.Pipeline.HLS.EtsHelperTest do
  @moduledoc false

  use ExUnit.Case, async: false

  alias Algora.Pipeline.HLS.EtsHelper

  @partial <<1, 2, 3>>
  @partial_name "muxed_segment_1_index.m4s"

  @wrong_partial_name "muxed_segment_101_index.m4s"

  @manifest "manifest"
  @manifest_name "index.m3u8"
  @delta_manifest "delta_manifest"
  @delta_manifest_name "index_delta.m3u8"

  @recent_partial {1, 1}
  @delta_recent_partial {2, 2}

  @videos_to_tables :videos_to_tables

  setup do
    video_uuid = UUID.uuid4()

    # Ets tables are not removed during tests because they are automatically removed when the owner process dies.
    # Therefore, using on_exit (as a separate process) would cause a crash.
    {:ok, table} = EtsHelper.add_video(video_uuid)

    %{video_uuid: video_uuid, table: table}
  end

  test "videos managment" do
    video_uuid = UUID.uuid4()
    assert {:error, :video_not_found} == EtsHelper.get_partial(video_uuid, @partial_name)

    {:ok, table} = EtsHelper.add_video(video_uuid)
    assert {:error, :already_exists} == EtsHelper.add_video(video_uuid)

    assert [{video_uuid, table}] == :ets.lookup(@videos_to_tables, video_uuid)

    :ok = EtsHelper.remove_video(video_uuid)
    assert {:error, "Video: #{video_uuid} doesn't exist"} == EtsHelper.remove_video(video_uuid)

    assert [] == :ets.lookup(@videos_to_tables, video_uuid)
  end

  test "partials managment", %{video_uuid: video_uuid, table: table} do
    assert {:error, :file_not_found} == EtsHelper.get_partial(video_uuid, @partial_name)

    EtsHelper.add_partial(table, @partial, @partial_name)

    assert {:ok, @partial} == EtsHelper.get_partial(video_uuid, @partial_name)

    assert {:error, :file_not_found} ==
             EtsHelper.get_partial(video_uuid, @wrong_partial_name)

    EtsHelper.delete_partial(table, @partial_name)

    assert {:error, :file_not_found} == EtsHelper.get_partial(video_uuid, @partial_name)
  end

  test "manifests managment", %{video_uuid: video_uuid, table: table} do
    assert {:error, :file_not_found} == EtsHelper.get_manifest(video_uuid, @manifest_name)
    assert {:error, :file_not_found} == EtsHelper.get_delta_manifest(video_uuid, @delta_manifest_name)

    EtsHelper.update_manifest(table, @manifest, @manifest_name)

    assert {:ok, @manifest} == EtsHelper.get_manifest(video_uuid, @manifest_name)
    assert {:error, :file_not_found} == EtsHelper.get_delta_manifest(video_uuid, @delta_manifest_name)

    EtsHelper.update_delta_manifest(table, @delta_manifest, @delta_manifest_name)

    assert {:ok, @manifest} == EtsHelper.get_manifest(video_uuid,@manifest_name)
    assert {:ok, @delta_manifest} == EtsHelper.get_delta_manifest(video_uuid, @delta_manifest_name)
  end

  test "recent partial managment", %{video_uuid: video_uuid, table: table} do
    assert {:error, :file_not_found} == EtsHelper.get_recent_partial(video_uuid, @manifest_name)
    assert {:error, :file_not_found} == EtsHelper.get_delta_recent_partial(video_uuid, @delta_manifest_name)

    EtsHelper.update_recent_partial(table, @recent_partial, @manifest_name)

    assert {:ok, @recent_partial} == EtsHelper.get_recent_partial(video_uuid, @manifest_name)
    assert {:error, :file_not_found} == EtsHelper.get_delta_recent_partial(video_uuid, @delta_manifest_name)

    EtsHelper.update_delta_recent_partial(table, @delta_recent_partial, @delta_manifest_name)

    assert {:ok, @recent_partial} == EtsHelper.get_recent_partial(video_uuid, @manifest_name)
    assert {:ok, @delta_recent_partial} == EtsHelper.get_delta_recent_partial(video_uuid, @delta_manifest_name)
  end
end
