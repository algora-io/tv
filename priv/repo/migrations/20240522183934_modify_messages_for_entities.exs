defmodule Algora.Repo.Local.Migrations.ModifyMessagesForEntities do
  use Ecto.Migration

  def change do
    alter table(:messages) do
      add :entity_id, references(:entities)
    end

    execute """
    INSERT INTO entities (user_id, name, handle, avatar_url, platform, platform_id, platform_meta, inserted_at, updated_at)
    SELECT id, name, handle, avatar_url, 'algora', id::text, '{}', NOW(), NOW()
    FROM users
    """

    execute """
    UPDATE messages
    SET entity_id = entities.id
    FROM entities
    WHERE messages.user_id = entities.user_id
    """

    alter table("messages") do
      modify :entity_id, :integer, null: false
    end

    create index(:messages, [:entity_id])
  end
end
