defmodule Algora.Repo.Migrations.AddThumbnailUrlToVideo do
  use Ecto.Migration

  def up do
    alter table("videos") do
      add :thumbnail_url, :string
    end

    execute "update videos set thumbnail_url = format('%s/index.jpeg', url_root) where url_root is not null and thumbnails_ready = 't'"

    execute "update videos set thumbnail_url = format('https://i.ytimg.com/vi/%s/hqdefault.jpg', substr(url,29)) where url like 'https://youtube.com/watch?v=%'"
  end

  def down do
    alter table("videos") do
      remove :thumbnail_url, :string
    end
  end
end
