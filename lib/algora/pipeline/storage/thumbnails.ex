defmodule Algora.Pipeline.Storage.Thumbnails do
  @moduledoc false

  require Membrane.Logger
  alias Algora.Library

  @thumbnail_markers [
    %{minutes: 0, segment_sn: 0},
    %{minutes: 1, segment_sn: 6},
    %{minutes: 2, segment_sn: 14},
    %{minutes: 4, segment_sn: 28},
    %{minutes: 8, segment_sn: 57},
    %{minutes: 16, segment_sn: 120}
  ]

  @pubsub Algora.PubSub

  def store_thumbnail(video, video_header, contents, marker) do
    with {:ok, video} <- Library.store_thumbnail(video, video_header <> contents, marker),
         {:ok, video} <- Library.store_og_image(video, marker) do
      broadcast_thumbnails_generated!(video)
    else
      _ ->
        Membrane.Logger.error("Could not generate thumbnails for video #{video.id}")
    end
  end

  def find_marker(segment_sn) do
    Enum.find(@thumbnail_markers, fn marker ->
      marker.segment_sn == segment_sn
    end)
  end

  def is_last_marker?(marker) do
    List.last(@thumbnail_markers) == marker
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
