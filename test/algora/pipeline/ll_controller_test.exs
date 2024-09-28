defmodule Algora.Pipeline.HLS.LLControllerTest do
  @moduledoc false

  use ExUnit.Case, async: true

  alias Algora.Pipeline.HLS.{LLController, EtsHelper}

  @manifest "index.m3u8"
  @delta_manifest "manifest_delta_index.m3u8"
  @manifest_content "manifest"

  @partial {1, 1}
  @partial_name "muxed_segment_1_index_1_part.m4s"
  @partial_content <<1, 2, 3>>

  @next_partial {1, 2}
  @next_partial_name "muxed_segment_1_index_2_part.m4s"
  @next_partial_content <<1, 2, 3, 4>>

  @future_partial_name "muxed_segment_1_index_4_part.m4s"

  @videos_to_tables :videos_to_tables

  setup %{tmp_dir: tmp_dir} do
    video_uuid = UUID.uuid4()
    directory = Path.join(tmp_dir, video_uuid)

    # LLController is not removed at all in tests
    # It removes itself when parent process is killed
    LLController.start(video_uuid, directory)

    %{video_uuid: video_uuid, directory: directory}
  end

  @tag :tmp_dir
  test "video managment", %{video_uuid: video_uuid, directory: directory} do
    {:error, {:already_started, _pid}} = LLController.start(video_uuid, directory)
    {:error, :already_exists} = EtsHelper.add_video(video_uuid)

    LLController.stop(video_uuid)

    # wait for ets to be removed
    Process.sleep(200)

    assert {:error, :video_not_found} == EtsHelper.get_manifest(video_uuid, @manifest)

    assert {:ok, _pid} = LLController.start(video_uuid, directory)
  end

  @tag :tmp_dir
  test "manifest request", %{video_uuid: video_uuid} do
    assert {:error, :file_not_found} == LLController.handle_manifest_request(video_uuid, @partial, @manifest)

    {:ok, table} = get_table_for_video(video_uuid)

    assert {:error, :file_not_found} == LLController.handle_manifest_request(video_uuid, @partial, @manifest)

    EtsHelper.update_recent_partial(table, @partial, @manifest)
    EtsHelper.update_manifest(table, @manifest_content, @manifest)
    LLController.update_recent_partial(video_uuid, @partial, :manifest, @manifest)

    assert {:ok, @manifest_content} == LLController.handle_manifest_request(video_uuid, @partial, @manifest)

    task =
      Task.async(fn ->
        LLController.handle_manifest_request(video_uuid, @next_partial, @manifest)
      end)

    assert nil == Task.yield(task, 500)

    LLController.update_recent_partial(video_uuid, @next_partial, :manifest, @manifest)

    assert {:ok, @manifest_content} == Task.await(task)
  end

  @tag :tmp_dir
  test "delta manifest request", %{video_uuid: video_uuid} do
    assert {:error, :file_not_found} ==
             LLController.handle_delta_manifest_request(video_uuid, @partial, @delta_manifest)

    {:ok, table} = get_table_for_video(video_uuid)

    assert {:error, :file_not_found} ==
             LLController.handle_delta_manifest_request(video_uuid, @partial, @delta_manifest)

    EtsHelper.update_delta_recent_partial(table, @partial, @delta_manifest)
    EtsHelper.update_delta_manifest(table, @manifest_content, @delta_manifest)
    LLController.update_recent_partial(video_uuid, @partial, :delta_manifest, @delta_manifest)

    assert {:ok, @manifest_content} ==
             LLController.handle_delta_manifest_request(video_uuid, @partial, @delta_manifest)

    task =
      Task.async(fn ->
        LLController.handle_delta_manifest_request(video_uuid, @next_partial, @delta_manifest)
      end)

    assert nil == Task.yield(task, 500)

    LLController.update_recent_partial(video_uuid, @next_partial, :delta_manifest, @delta_manifest)

    assert {:ok, @manifest_content} == Task.await(task)
  end

  @tag :tmp_dir
  test "partial request", %{video_uuid: video_uuid} do
    assert {:error, :file_not_found} ==
             LLController.handle_partial_request(video_uuid, @partial_name)

    {:ok, table} = get_table_for_video(video_uuid)

    assert {:error, :file_not_found} ==
             LLController.handle_partial_request(video_uuid, @partial_name)

    EtsHelper.add_partial(table, @partial_content, @partial_name)

    assert {:ok, @partial_content} ==
             LLController.handle_partial_request(video_uuid, @partial_name)

    assert {:error, :file_not_found} ==
             LLController.handle_partial_request(video_uuid, "wrong_partial_name")
  end

  @tag :tmp_dir
  test "preload hint request", %{video_uuid: video_uuid} do
    {:ok, table} = get_table_for_video(video_uuid)

    EtsHelper.add_partial(table, @partial_content, @partial_name)
    EtsHelper.update_recent_partial(table, @partial, @manifest)
    LLController.update_recent_partial(video_uuid, @partial, :manifest, @manifest)

    task =
      Task.async(fn -> LLController.handle_partial_request(video_uuid, @next_partial_name) end)

    assert nil == Task.yield(task, 500)

    EtsHelper.add_partial(table, @next_partial_content, @next_partial_name)
    EtsHelper.update_recent_partial(table, @next_partial, @manifest)
    LLController.update_recent_partial(video_uuid, @next_partial, :manifest, @manifest)

    assert {:ok, @next_partial_content} == Task.await(task)
    assert {:error, :file_not_found} ==
             LLController.handle_partial_request(video_uuid, @future_partial_name)
  end

  defp get_table_for_video(video_uuid) do
    case :ets.lookup(@videos_to_tables, video_uuid) do
      [{^video_uuid, table}] -> {:ok, table}
      _ -> {:error, :not_found}
    end
  end
end
