defmodule Algora.Repo.Migrations.AddVerticalThumbnailUrlToVideo do
  use Ecto.Migration

  def change do
    alter table("videos") do
      add :vertical_thumbnail_url, :string
    end
  end
end
