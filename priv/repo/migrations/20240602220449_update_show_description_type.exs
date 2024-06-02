defmodule Algora.Repo.Local.Migrations.UpdateShowDescriptionType do
  use Ecto.Migration

  def change do
    alter table("shows") do
      modify :description, :text
    end
  end
end
