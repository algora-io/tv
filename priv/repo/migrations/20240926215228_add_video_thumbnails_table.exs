defmodule Algora.Repo.Local.Migrations.AddVideoThumbnailsTable do
  use Ecto.Migration

  def change do
    create table(:video_thumbnails) do
      add :minutes, :integer, null: false
      add :thumbnail_url, :string, null: false
      add :video_id, references(:videos, on_delete: :nothing), null: false

      timestamps()
    end

    create index(:video_thumbnails, [:video_id])
    create index(:video_thumbnails, [:video_id, :minutes], unique: true)
  end
end
