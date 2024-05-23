defmodule Algora.Repo.Local.Migrations.CreateEvents do
  use Ecto.Migration

  def change do
    create table(:events) do
      add :actor_id, :string, null: false
      add :user_id, references(:users)
      add :video_id, references(:videos)
      add :channel_id, references(:users)
      add :name, :string, null: false

      timestamps()
    end

    create index(:events, [:actor_id])
    create index(:events, [:user_id])
    create index(:events, [:video_id])
    create index(:events, [:channel_id])
  end
end
