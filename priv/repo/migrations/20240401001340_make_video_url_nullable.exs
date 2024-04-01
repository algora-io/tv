defmodule Algora.Repo.Local.Migrations.MakeVideoUrlNullable do
  use Ecto.Migration

  def change do
    alter table("videos") do
      modify :url, :string, null: true
    end
  end
end
