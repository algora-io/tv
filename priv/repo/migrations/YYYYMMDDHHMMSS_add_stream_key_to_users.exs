defmodule Algora.Repo.Migrations.AddStreamKeyToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :stream_key, :string
      add :stream_key_created_at, :utc_datetime
      add :stream_key_last_used_at, :utc_datetime
    end

    create unique_index(:users, [:stream_key])
    create index(:users, [:stream_key_created_at])
    create index(:users, [:stream_key_last_used_at])
  end
end
