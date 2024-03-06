defmodule Algora.Repo.Migrations.RemoveThumbnailsReadyFromVideo do
  use Ecto.Migration

  def change do
    alter table("videos") do
      remove :thumbnails_ready
    end
  end
end
