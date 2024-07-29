defmodule Algora.Repo.Migrations.CreateAdImpressions do
  use Ecto.Migration

  def change do
    create table(:ad_impressions) do
      add :duration, :integer
      add :concurrent_viewers, :integer
      add :ad_id, references(:ads, on_delete: :nothing)
      add :video_id, references(:videos, on_delete: :nothing)

      timestamps()
    end

    create index(:ad_impressions, [:ad_id])
    create index(:ad_impressions, [:video_id])
  end
end
