defmodule Algora.Repo.Local.Migrations.AddFormatToVideo do
  use Ecto.Migration

  def up do
    alter table("videos") do
      add :format, :integer
    end

    execute "update videos set format = 1 where type = 1 and url not like 'https://youtube.com/watch?v=%'"

    execute "update videos set format = 2 where type = 2"

    execute "update videos set format = 3 where type = 1 and url like 'https://youtube.com/watch?v=%'"

    alter table("videos") do
      modify :format, :integer, null: false
    end
  end

  def down do
    alter table("videos") do
      remove :format
    end
  end
end
