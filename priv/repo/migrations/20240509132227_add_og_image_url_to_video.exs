defmodule Algora.Repo.Local.Migrations.AddOgImageUrlToVideo do
  use Ecto.Migration

  def change do
    alter table("videos") do
      add :og_image_url, :string
    end
  end
end
