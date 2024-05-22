defmodule Algora.Repo.Local.Migrations.AddProviderRefreshTokenToIdentities do
  use Ecto.Migration

  def change do
    alter table("identities") do
      add :provider_refresh_token, :string
    end
  end
end
