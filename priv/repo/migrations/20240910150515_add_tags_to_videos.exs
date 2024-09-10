defmodule Algora.Repo.Local.Migrations.AddTagsToVideos do
  use Ecto.Migration

  def change do
    alter table(:videos) do
      add :tags, {:array, :string}
    end
  end
end
