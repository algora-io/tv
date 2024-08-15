defmodule Algora.Repo.Migrations.CreateAdRelatedTables do
  use Ecto.Migration

  def change do
    create table(:product_reviews) do
      add :clip_from, :integer, null: false
      add :clip_to, :integer, null: false
      add :thumbnail_url, :string
      add :ad_id, references(:ads, on_delete: :nothing), null: false
      add :video_id, references(:videos, on_delete: :nothing), null: false

      timestamps()
    end

    create index(:product_reviews, [:ad_id])
    create index(:product_reviews, [:video_id])

    create table(:ad_appearances) do
      add :airtime, :integer, null: false
      add :ad_id, references(:ads, on_delete: :nothing), null: false
      add :video_id, references(:videos, on_delete: :nothing), null: false

      timestamps()
    end

    create index(:ad_appearances, [:ad_id])
    create index(:ad_appearances, [:video_id])

    create table(:content_metrics) do
      add :algora_stream_url, :string
      add :twitch_stream_url, :string
      add :youtube_video_url, :string
      add :twitter_video_url, :string
      add :twitch_avg_concurrent_viewers, :integer
      add :twitch_views, :integer
      add :youtube_views, :integer
      add :twitter_views, :integer
      add :video_id, references(:videos, on_delete: :nothing), null: false

      timestamps()
    end

    create index(:content_metrics, [:video_id])
  end
end
