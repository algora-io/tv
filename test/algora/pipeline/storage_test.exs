defmodule Algora.Pipeline.StorageTest do
  @moduledoc false

  use ExUnit.Case, async: true

  alias Algora.Pipeline.HLS.{EtsHelper, LLController}
  alias Algora.Pipeline.Storage
  alias Algora.Library.Video

  @segment_name "muxed_segment_0_manifest.m4s"
  @segment_content <<1, 2, 3>>

  @partial_name "muxed_segment_0_manifest_0_part.m4s"
  @partial_content <<1, 2, 3, 4>>
  @partial_sn {0, 0}

  @manifest_name "manifest.m3u8"
  @manifest_content "manifest_content"

  @delta_manifest_name "manifest_delta.m3u8"
  @delta_manifest_content "delta_manifest_content"

  @header_name "header"
  @header_content <<1, 2, 3, 4, 5>>

  setup %{tmp_dir: tmp_dir} do
    video_uuid = UUID.uuid4()
    directory = Path.join(tmp_dir, video_uuid)

    File.mkdir_p!(directory)

    config = %Storage{directory: directory, video: %Video{ uuid: video_uuid }}

    storage = Storage.init(config)
    {:ok, _pid} = LLController.start(video_uuid, directory)

    %{storage: storage, directory: directory, video_uuid: video_uuid}
  end

  @tag :tmp_dir
  test "store partial", %{storage: storage, video_uuid: video_uuid} do
    {:ok, _storage} = store_partial(storage)

    :timer.sleep(200)

    assert {:ok, @partial_content} == EtsHelper.get_partial(video_uuid, @partial_name)
  end

  @tag :tmp_dir
  test "store manifest", %{storage: storage, video_uuid: video_uuid} do
    {:ok, storage} = store_partial(storage)
    {:ok, _storage} = store_manifest(storage)

    :timer.sleep(200)

    assert {:ok, @manifest_content} == EtsHelper.get_manifest(video_uuid, @manifest_name)
    assert {:ok, @partial_sn} == EtsHelper.get_recent_partial(video_uuid, @manifest_name)

    pid = self()

    spawn(fn ->
      {:ok, @manifest_content} = LLController.handle_manifest_request(video_uuid, @partial_sn, @manifest_name)
      send(pid, :manifest)
    end)

    assert_receive(:manifest)
  end

  @tag :tmp_dir
  @tag timeout: 1_000
  test "store delta manifest", %{storage: storage, video_uuid: video_uuid} do
    {:ok, storage} = store_partial(storage)
    {:ok, _storage} = store_delta_manifest(storage)

    :timer.sleep(200)

    assert {:ok, @delta_manifest_content} == EtsHelper.get_delta_manifest(video_uuid, @delta_manifest_name)
    assert {:ok, @partial_sn} == EtsHelper.get_delta_recent_partial(video_uuid, @delta_manifest_name)

    assert {:ok, @delta_manifest_content} ==
             LLController.handle_delta_manifest_request(video_uuid, @partial_sn, @delta_manifest_name)
  end

  defp store_segment(storage) do
    Storage.store(
      :parent_id,
      @segment_name,
      @segment_content,
      :metadata,
      %{mode: :binary, type: :segment},
      storage
    )
  end

  defp store_partial(storage) do
    Storage.store(
      :parent_id,
      @segment_name,
      @partial_content,
      %{partial_name: @partial_name, sequence_number: 0},
      %{mode: :binary, type: :partial_segment},
      storage
    )
  end

  defp store_manifest(storage) do
    Storage.store(
      :parent_id,
      @manifest_name,
      @manifest_content,
      :metadata,
      %{mode: :text, type: :manifest},
      storage
    )
  end

  defp store_delta_manifest(storage) do
    Storage.store(
      :parent_id,
      @delta_manifest_name,
      @delta_manifest_content,
      :metadata,
      %{mode: :text, type: :manifest},
      storage
    )
  end

  defp store_header(storage) do
    Storage.store(
      :parent_id,
      @header_name,
      @header_content,
      :metadata,
      %{mode: :binary, type: :header},
      storage
    )
  end
end
