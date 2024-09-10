defmodule Algora.Repo.Local.Migrations.AddTagsToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :tags, {:array, :string}
    end
  end
end
