defmodule Algora.Repo.Local.Migrations.AddDescriptionToVideo do
  use Ecto.Migration

  def change do
    alter table("videos") do
      add :description, :string
    end
  end
end
