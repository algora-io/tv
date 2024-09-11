defmodule Algora.Admin.GenerateBlurbThumbnails do
  import Ecto.Query
  alias Algora.Ads.ProductReview
  alias Algora.{Clipper, Repo, Storage}
  require Logger

  def run do
    for product_review <- fetch_product_reviews() do
      try do
        :ok = process_product_review(product_review)
      rescue
        e ->
          Logger.error(Exception.format(:error, e, __STACKTRACE__))
      end
    end
  end

  defp fetch_product_reviews do
    Repo.all(
      from pr in ProductReview,
        join: v in assoc(pr, :video),
        where: is_nil(pr.thumbnail_url),
        preload: [video: v]
    )
  end

  defp process_product_review(product_review) do
    with {:ok, thumbnail_path} <- create_thumbnail(product_review),
         {:ok, thumbnail_url} <- upload_thumbnail(thumbnail_path),
         {:ok, _updated_review} <- update_product_review(product_review, thumbnail_url) do
      IO.puts("Successfully processed ProductReview #{product_review.id}")
    else
      {:error, step, reason} ->
        IO.puts(
          "Error processing ProductReview #{product_review.id} at step #{step}: #{inspect(reason)}"
        )

        :error
    end
  end

  defp create_thumbnail(product_review) do
    video_path = generate_thumbnails(product_review)
    output_path = "/tmp/thumbnail_#{product_review.id}.jpg"

    case Thumbnex.create_thumbnail(video_path, output_path, time: product_review.clip_from) do
      :ok -> {:ok, output_path}
      error -> {:error, :create_thumbnail, error}
    end
  end

  defp upload_thumbnail(file_path) do
    uuid = Ecto.UUID.generate()
    remote_path = "blurbs/#{uuid}.jpg"

    case Algora.Storage.upload_from_filename(file_path, remote_path, fn _ -> nil end,
           content_type: "image/jpeg"
         ) do
      {:ok, _} ->
        bucket = Algora.config([:buckets, :media])
        %{scheme: scheme, host: host} = Application.fetch_env!(:ex_aws, :s3) |> Enum.into(%{})
        thumbnail_url = "#{scheme}#{host}/#{bucket}/#{remote_path}"
        {:ok, thumbnail_url}

      error ->
        {:error, :upload_thumbnail, error}
    end
  end

  defp update_product_review(product_review, thumbnail_url) do
    product_review
    |> Ecto.Changeset.change(thumbnail_url: thumbnail_url)
    |> Repo.update()
    |> case do
      {:ok, updated_review} -> {:ok, updated_review}
      error -> {:error, :update_product_review, error}
    end
  end

  def generate_thumbnails(product_review) do
    # Generate clipped manifest
    %{playlist: playlist, ss: _ss} =
      Clipper.clip(product_review.video, product_review.clip_from, product_review.clip_to)

    # Find MediaInit and first Segment
    {init_tag, segment_tag} = find_init_and_segment(playlist.timeline)

    # Download and concatenate files
    video_path = download_and_concatenate(init_tag, segment_tag, product_review.video)

    video_path
  end

  defp find_init_and_segment(timeline) do
    init_tag = Enum.find(timeline, &match?(%ExM3U8.Tags.MediaInit{}, &1))
    segments = Enum.filter(timeline, &match?(%ExM3U8.Tags.Segment{}, &1))

    segment_tag =
      case segments do
        [_, second | _] -> second
        [first | _] -> first
        _ -> nil
      end

    {init_tag, segment_tag}
  end

  defp download_and_concatenate(init_tag, segment_tag, video) do
    temp_dir = Path.join(System.tmp_dir!(), video.uuid)
    File.mkdir_p!(temp_dir)

    output_path = Path.join(temp_dir, "output.mp4")

    init_url = Storage.to_absolute(:video, video.uuid, init_tag.uri)
    segment_url = Storage.to_absolute(:video, video.uuid, segment_tag.uri)

    init_path = download_file(init_url, Path.join(temp_dir, "init.mp4"))
    segment_path = download_file(segment_url, Path.join(temp_dir, "segment.m4s"))

    ffmpeg_command = "ffmpeg -y -i \"concat:#{init_path}|#{segment_path}\" -c copy #{output_path}"
    System.cmd("sh", ["-c", ffmpeg_command])

    output_path
  end

  defp download_file(url, path) do
    {:ok, %{body: body}} = HTTPoison.get(url)
    File.write!(path, body)
    path
  end
end
