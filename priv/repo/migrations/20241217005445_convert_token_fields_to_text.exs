defmodule Algora.Repo.Local.Migrations.ConvertTokenFieldsToText do
  use Ecto.Migration

  def change do
    alter table(:identities) do
      modify :provider_token, :text, from: :string
      modify :provider_refresh_token, :text, from: :string
    end
  end
end
