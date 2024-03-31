defmodule Algora.Repo.Migrations.AddTransmuxedFromToVideo do
  use Ecto.Migration

  def change do
    alter table(:videos) do
      add :transmuxed_from_id, references(:videos, on_delete: :nothing)
    end

    create index(:videos, [:transmuxed_from_id])
  end
end
