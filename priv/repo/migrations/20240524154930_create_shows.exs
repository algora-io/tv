defmodule Algora.Repo.Migrations.CreateShows do
  use Ecto.Migration

  def change do
    create table(:shows) do
      add :title, :string, null: false
      add :description, :string
      add :slug, :citext, null: false
      add :scheduled_for, :naive_datetime
      add :image_url, :string
      add :url, :string
      add :user_id, references(:users, on_delete: :nothing)

      timestamps()
    end

    alter table(:events) do
      add :show_id, references(:shows)
    end

    alter table(:videos) do
      add :show_id, references(:shows)
    end

    create unique_index(:shows, [:slug])
    create index(:shows, [:user_id])
    create index(:events, [:show_id])
    create index(:videos, [:show_id])

    execute """
    INSERT INTO shows (title, slug, description, scheduled_for, image_url, url, user_id, inserted_at, updated_at)
    VALUES
    ('RFC 006 - Demos!', 'rfc', 'Deeeemoooo time :)\n\nFounders demo''ing their prototypes and new products\n\nI will give investor POV feedback if useful!', '2024-06-07 16:00:00.00000+00', 'https://images.lumacdn.com/cdn-cgi/image/format=auto,fit=cover,dpr=2,quality=75,width=280,height=280/event-covers/o0/fe94665f-2ea2-4d22-abb1-8270a7386080', 'https://rfc.to', 7, NOW(), NOW()),
    ('eu/acc - Update :)', 'eu-acc', null, '2024-05-31 16:00:00.00000+00', 'https://images.lumacdn.com/cdn-cgi/image/format=auto,fit=cover,dpr=2,quality=75,width=280,height=280/event-covers/2s/45fc04c6-94ae-4899-9a61-49ed0f028cc7', 'https://rfc.to', 7, NOW(), NOW());
    """
  end
end
