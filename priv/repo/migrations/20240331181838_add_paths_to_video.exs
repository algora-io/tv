defmodule Algora.Repo.Local.Migrations.AddPathsToVideo do
  use Ecto.Migration

  def up do
    alter table("videos") do
      add :remote_path, :string
      add :local_path, :string
    end

    execute "update videos set remote_path = format('%s/%s', uuid, filename) where filename is not null"
  end

  def down do
    alter table("videos") do
      remove :remote_path
      remove :local_path
    end
  end
end
