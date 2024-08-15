defmodule Algora.Repo.Local.Migrations.AddOgImageUrlToAds do
  use Ecto.Migration

  def change do
    alter table(:ads) do
      add :og_image_url, :string
    end
  end
end
