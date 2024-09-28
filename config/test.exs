import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :algora, Algora.Repo,
  url: System.get_env("TEST_DATABASE_URL"),
  show_sensitive_data_on_connection_error: true,
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

config :algora, Algora.Repo.Local,
  url: System.get_env("TEST_DATABASE_URL"),
  show_sensitive_data_on_connection_error: true,
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10,
  priv: "priv/repo"

config :algora, Oban, testing: :inline

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :algora, AlgoraWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  server: false

config :algora, AlgoraWeb.Embed.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4003],
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Disable swoosh api client as it is only required for production adapters.
config :swoosh, :api_client, false
