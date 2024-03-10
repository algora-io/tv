defmodule Algora.Repo.Local do
  use Ecto.Repo,
    otp_app: :algora,
    adapter: Ecto.Adapters.Postgres

  @env Mix.env()

  # Dynamically configure the database url based on runtime and build
  # environments.
  def init(_type, config) do
    # url = Fly.Postgres.rewrite_database_url!(config)
    # dbg(url)

    Fly.Postgres.config_repo_url(config, @env)
  end
end

defmodule Algora.Repo do
  use Fly.Repo, local_repo: Algora.Repo.Local
end
