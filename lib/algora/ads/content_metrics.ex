defmodule Algora.Ads.ContentMetrics do
  use Ecto.Schema
  import Ecto.Changeset
  alias Algora.Library.Video

  schema "content_metrics" do
    field :algora_stream_url, :string
    field :twitch_stream_url, :string
    field :youtube_video_url, :string
    field :twitter_video_url, :string
    field :twitch_avg_concurrent_viewers, :integer
    field :twitch_views, :integer
    field :youtube_views, :integer
    field :twitter_views, :integer

    belongs_to :video, Video

    timestamps()
  end

  def changeset(content_metrics, attrs) do
    content_metrics
    |> cast(attrs, [
      :algora_stream_url,
      :twitch_stream_url,
      :youtube_video_url,
      :twitter_video_url,
      :twitch_avg_concurrent_viewers,
      :twitch_views,
      :youtube_views,
      :twitter_views,
      :video_id
    ])
    |> validate_required([:video_id])
    |> foreign_key_constraint(:video_id)
  end
end
