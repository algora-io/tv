defmodule Algora.Repo.Migrations.CreateSubtitles do
  use Ecto.Migration

  def change do
    create table(:subtitles) do
      add :body, :text
      add :start, :float
      add :end, :float
      add :video_id, references(:videos, on_delete: :nothing)

      timestamps()
    end

    create index(:subtitles, [:video_id])
  end
end
