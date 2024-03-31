defmodule Algora.Repo.Local.Migrations.AddFilenameToVideo do
  use Ecto.Migration

  def up do
    alter table("videos") do
      add :filename, :string
    end

    execute "update videos set filename = replace(url, format('%s/', url_root), '') where url_root is not null"
  end

  def down do
    alter table("videos") do
      remove :filename
    end
  end
end
