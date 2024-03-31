defmodule Algora.Storage do
  @behaviour Membrane.HTTPAdaptiveStream.Storage

  import Ecto.Changeset
  require Membrane.Logger
  alias Algora.{Repo, Library}

  @enforce_keys [:video]
  defstruct @enforce_keys ++ [video_header: <<>>]

  @type t :: %__MODULE__{
          video: Library.Video.t(),
          video_header: <<>>
        }

  @impl true
  def init(%__MODULE__{} = config), do: config

  @impl true
  def store(
        parent_id,
        name,
        contents,
        metadata,
        ctx,
        %{video: video} = state
      ) do
    path = "#{video.uuid}/#{name}"

    with {:ok, _} <- upload(contents, path, upload_opts(ctx)),
         {:ok, state} <- process_contents(parent_id, name, contents, metadata, ctx, state) do
      {:ok, state}
    else
      {:error, reason} = err ->
        Membrane.Logger.error("Failed to upload #{path}: #{reason}")
        {err, state}
    end
  end

  defp upload_opts(%{type: :manifest} = _ctx) do
    [{:cache_control, "no-cache, no-store, private"}]
  end

  defp upload_opts(_ctx), do: []

  @impl true
  def remove(_parent_id, _name, _ctx, state) do
    {{:error, :not_implemented}, state}
  end

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
         %{video: %{thumbnail_url: nil} = video, video_header: video_header} = state
       ) do
    with :ok <- Library.store_thumbnail(video, video_header <> contents),
         {:ok, video} =
           video
           |> change()
           |> put_change(:thumbnail_url, "#{video.url_root}/index.jpeg")
           |> Repo.update(),
         :ok <- broadcast_thumbnails_generated(video) do
      {:ok, %{state | video: video}}
    end
  end

  defp process_contents(_parent_id, _name, _contents, _metadata, _ctx, state) do
    {:ok, state}
  end

  def upload(contents, remote_path, opts \\ []) do
    Algora.config([:files, :bucket])
    |> ExAws.S3.put_object(remote_path, contents, opts)
    |> ExAws.request([])
  end

  def upload_from_filename(local_path, remote_path, cb \\ fn -> nil end, opts \\ []) do
    %{size: size} = File.stat!(local_path)

    chunk_size = 5 * 1024 * 1024

    result =
      ExAws.S3.Upload.stream_file(local_path, [{:chunk_size, chunk_size}])
      |> Stream.map(fn chunk ->
        cb.(%{done: chunk_size, total: size})
        chunk
      end)
      |> ExAws.S3.upload(Algora.config([:files, :bucket]), remote_path, opts)
      |> ExAws.request([])

    result
  end

  defp broadcast_thumbnails_generated(video) do
    Phoenix.PubSub.broadcast(
      Algora.PubSub,
      Library.topic_livestreams(),
      {__MODULE__, %Library.Events.ThumbnailsGenerated{video: video}}
    )
  end
end
