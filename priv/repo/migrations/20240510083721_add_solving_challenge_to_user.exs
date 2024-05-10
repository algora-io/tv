defmodule Algora.Repo.Local.Migrations.AddSolvingChallengeToUser do
  use Ecto.Migration

  def change do
    alter table("users") do
      add :solving_challenge, :boolean, default: false
    end
  end
end
