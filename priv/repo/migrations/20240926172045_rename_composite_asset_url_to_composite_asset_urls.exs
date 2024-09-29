defmodule Algora.Repo.Local.Migrations.RenameCompositeAssetUrlToCompositeAssetUrls do
  use Ecto.Migration

  def up do
    alter table(:ads) do
      add :composite_asset_urls, {:array, :string}, default: []
    end

    execute """
    UPDATE ads
    SET composite_asset_urls = ARRAY[composite_asset_url]
    WHERE composite_asset_url IS NOT NULL
    """

    alter table(:ads) do
      remove :composite_asset_url
    end
  end

  def down do
    alter table(:ads) do
      add :composite_asset_url, :string
    end

    execute """
    UPDATE ads
    SET composite_asset_url = composite_asset_urls[1]
    WHERE composite_asset_urls IS NOT NULL
    """

    alter table(:ads) do
      remove :composite_asset_urls
    end
  end
end
