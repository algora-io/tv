defmodule Algora.Repo.Local.Migrations.AddDeletedAtToVideos do
  use Ecto.Migration

  def change do
    alter table(:videos) do
      add :deleted_at, :naive_datetime
    end

    create index(:videos, [:deleted_at])
  end
end
