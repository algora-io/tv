defmodule Algora.Repo.Migrations.CreateAds do
  use Ecto.Migration

  def change do
    create table(:ads) do
      add :verified, :boolean, default: false, null: false
      add :website_url, :string
      add :composite_asset_url, :string
      add :asset_url, :string
      add :logo_url, :string
      add :qrcode_url, :string
      add :start_date, :naive_datetime
      add :end_date, :naive_datetime
      add :total_budget, :integer
      add :daily_budget, :integer
      add :tech_stack, {:array, :string}
      add :click_count, :integer
      add :status, :string
      add :user_id, references(:users, on_delete: :nothing)

      timestamps()
    end

    create index(:ads, [:user_id])
  end
end
