defmodule Algora.Repo.Local.Migrations.AddSlugToAds do
  use Ecto.Migration

  def change do
    alter table(:ads) do
      add :slug, :string
    end

    create unique_index(:ads, [:slug])
  end
end
