defmodule Algora.Repo.Local.Migrations.AddFeaturedToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :featured, :boolean, default: false
    end
  end
end
