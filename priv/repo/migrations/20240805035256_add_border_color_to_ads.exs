defmodule Algora.Repo.Local.Migrations.AddBorderColorToAds do
  use Ecto.Migration

  def change do
    alter table(:ads) do
      add :border_color, :string
    end
  end
end
