defmodule Algora.Repo.Local.Migrations.CreateDestinations do
  use Ecto.Migration

  def change do
    create table(:destinations) do
      add :rtmp_url, :string, null: false
      add :stream_key, :string, null: false
      add :active, :boolean, default: true, null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:destinations, [:user_id])
  end
end
