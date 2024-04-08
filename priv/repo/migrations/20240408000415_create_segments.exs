defmodule Algora.Repo.Local.Migrations.CreateSegments do
  use Ecto.Migration

  def change do
    create table(:segments) do
      add :body, :text
      add :start, :float
      add :end, :float
      add :embedding, :map
      add :starting_subtitle_id, references(:subtitles, on_delete: :nothing), null: false
      add :ending_subtitle_id, references(:subtitles, on_delete: :nothing), null: false
      add :video_id, references(:videos, on_delete: :nothing), null: false

      timestamps()
    end

    create index(:segments, [:video_id])
    create index(:segments, [:starting_subtitle_id])
    create index(:segments, [:ending_subtitle_id])
  end
end
