defmodule Algora.Repo.Local.Migrations.AddPlatformIdToMessage do
  use Ecto.Migration

  def change do
    alter table("messages") do
      add :platform_id, :string
    end
  end
end
