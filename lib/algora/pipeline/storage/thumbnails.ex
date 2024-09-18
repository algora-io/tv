defmodule Algora.Pipeline.Storage.Thumbnails do
  @moduledoc false

  require Membrane.Logger
  alias Algora.Library

  @thumbnail_intervals [0, 1, 2, 4, 8, 16]
  @segments_per_minute 30

  @pubsub Algora.PubSub

  def store_thumbnail(video, video_header, contents) do
    with {:ok, video} <- Library.store_thumbnail(video, video_header <> contents),
         {:ok, video} <- Library.store_og_image(video) do
      broadcast_thumbnails_generated!(video)
    else
      _ ->
        Membrane.Logger.error("Could not generate thumbnails for video #{video.id}")
    end
  end

  def thumbnail_interval_segments() do
    @thumbnail_intervals
      |> Enum.map(& &1 * @segments_per_minute)
  end

  defp broadcast_thumbnails_generated!(video) do
    # HACK: this shouldn't be necessary
    # atm we need it because initially the video does not have the user field set
    video = Library.get_video!(video.id)

    Phoenix.PubSub.broadcast!(
      @pubsub,
      Library.topic_livestreams(),
      {__MODULE__, %Library.Events.ThumbnailsGenerated{video: video}}
    )
  end
end
