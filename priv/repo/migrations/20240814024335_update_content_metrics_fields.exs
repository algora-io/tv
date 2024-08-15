defmodule Algora.Repo.Local.Migrations.UpdateContentMetricsFields do
  use Ecto.Migration

  def change do
    execute "UPDATE content_metrics SET twitch_avg_concurrent_viewers = COALESCE(twitch_avg_concurrent_viewers, 0)"
    execute "UPDATE content_metrics SET twitch_views = COALESCE(twitch_views, 0)"
    execute "UPDATE content_metrics SET youtube_views = COALESCE(youtube_views, 0)"
    execute "UPDATE content_metrics SET twitter_views = COALESCE(twitter_views, 0)"

    alter table(:content_metrics) do
      modify :twitch_avg_concurrent_viewers, :integer, null: false, default: 0, from: :integer
      modify :twitch_views, :integer, null: false, default: 0, from: :integer
      modify :youtube_views, :integer, null: false, default: 0, from: :integer
      modify :twitter_views, :integer, null: false, default: 0, from: :integer
    end
  end
end
