defmodule Algora.Repo.Migrations.CreateShows do
  use Ecto.Migration

  def change do
    create table(:shows) do
      add :title, :string, null: false
      add :slug, :citext, null: false
      add :scheduled_for, :naive_datetime
      add :image_url, :string
      add :user_id, references(:users, on_delete: :nothing)

      timestamps()
    end

    create unique_index(:shows, [:slug])
    create index(:shows, [:user_id])
  end
end
