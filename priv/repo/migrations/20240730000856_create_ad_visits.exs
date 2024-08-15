defmodule Algora.Repo.Migrations.CreateAdVisits do
  use Ecto.Migration

  def change do
    create table(:ad_visits) do
      add :ad_id, references(:ads, on_delete: :nothing)
      add :video_id, references(:videos, on_delete: :nothing)

      timestamps()
    end

    alter table(:ads) do
      remove :click_count
    end

    create index(:ad_visits, [:ad_id])
    create index(:ad_visits, [:video_id])
  end
end
