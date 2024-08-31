defmodule Algora.Repo.Local.Migrations.AddCorruptedToVideo do
  use Ecto.Migration

  def change do
    alter table(:videos) do
      add :corrupted, :boolean, default: false
    end
  end
end
