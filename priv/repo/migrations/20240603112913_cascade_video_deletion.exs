defmodule Algora.Repo.Local.Migrations.CascadeVideoDeletion do
  use Ecto.Migration

  def change do
    drop constraint(:messages, :messages_video_id_fkey)
    drop constraint(:events, :events_video_id_fkey)

    alter table(:messages) do
      modify :video_id, references(:videos, on_delete: :delete_all)
    end

    alter table(:events) do
      modify :video_id, references(:videos, on_delete: :delete_all)
    end
  end
end
