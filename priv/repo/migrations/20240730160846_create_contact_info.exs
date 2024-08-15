defmodule Algora.Repo.Migrations.CreateContactInfo do
  use Ecto.Migration

  def change do
    create table(:contact_info) do
      add :email, :string
      add :website_url, :string
      add :revenue, :string
      add :company_location, :string

      timestamps()
    end
  end
end
