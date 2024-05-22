defmodule Algora.Repo.Local.Migrations.CreateEntities do
  use Ecto.Migration

  def change do
    create table(:entities) do
      add :user_id, references(:users)
      add :name, :string
      add :handle, :citext, null: false
      add :avatar_url, :string
      add :platform, :string, null: false
      add :platform_id, :string, null: false
      add :platform_meta, :map, default: "{}", null: false

      timestamps()
    end

    create unique_index(:entities, [:platform, :platform_id])
    create unique_index(:entities, [:platform, :handle])
    create index(:entities, [:platform])
    create index(:entities, [:platform_id])
    create index(:entities, [:handle])
  end
end
