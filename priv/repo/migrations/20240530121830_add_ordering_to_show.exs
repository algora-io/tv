defmodule Algora.Repo.Local.Migrations.AddOrderingToShow do
  use Ecto.Migration

  def change do
    alter table("shows") do
      add :ordering, :integer
    end
  end
end
