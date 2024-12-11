defmodule Algora.Repo.Local.Migrations.AddGinIndexToTags do
  use Ecto.Migration

  def up do
     execute("create index users_tags_index on users using gin (tags);")
     execute("create index videos_tags_index on videos using gin (tags);")
  end

  def down do
     execute("drop index users_tags_index;")
     execute("drop index videos_tags_index;")
  end
end
