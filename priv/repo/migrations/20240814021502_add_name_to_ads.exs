defmodule Algora.Repo.Local.Migrations.AddNameToAds do
  use Ecto.Migration

  def change do
    alter table(:ads) do
      add :name, :string
    end

    execute "UPDATE ads SET name = INITCAP(slug)"
  end
end
