defmodule Algora.Repo.Migrations.InitCore do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS citext", ""

    create table(:users) do
      add :email, :citext, null: false
      add :name, :string
      add :handle, :citext, null: false
      add :channel_tagline, :string
      add :avatar_url, :string
      add :external_homepage_url, :string
      add :videos_count, :integer, null: false, default: 0
      add :is_live, :boolean, null: false, default: false
      add :stream_key, :string
      add :visibility, :integer, null: false, default: 1
      add :bounties_count, :integer
      add :tech, :map
      add :orgs_contributed, :map

      timestamps()
    end

    create unique_index(:users, [:email])
    create unique_index(:users, [:handle])

    create table(:identities) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :provider, :string, null: false
      add :provider_token, :string, null: false
      add :provider_email, :string, null: false
      add :provider_login, :string, null: false
      add :provider_id, :string, null: false
      add :provider_meta, :map, default: "{}", null: false

      timestamps()
    end

    create index(:identities, [:user_id])
    create index(:identities, [:provider])
    create unique_index(:identities, [:user_id, :provider])

    create table(:videos) do
      add :duration, :integer, default: 0, null: false
      add :title, :string, null: false
      add :type, :integer, null: false
      add :is_live, :boolean, null: false, default: false
      add :thumbnails_ready, :boolean, null: false, default: false
      add :url, :string, null: false
      add :url_root, :string
      add :uuid, :string
      add :visibility, :integer, null: false, default: 1
      add :user_id, references(:users, on_delete: :nothing)

      timestamps()
    end

    create index(:videos, [:user_id])

    create table(:messages) do
      add :body, :text
      add :user_id, references(:users, on_delete: :nothing)
      add :video_id, references(:videos, on_delete: :nothing)

      timestamps()
    end

    create index(:messages, [:user_id])
    create index(:messages, [:video_id])
  end
end
