# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :algora,
  replica: Algora.ReplicaRepo,
  ecto_repos: [Algora.Repo],
  rtmp_port: 9006

config :algora, Oban,
  repo: Algora.Repo,
  plugins: [Oban.Plugins.Pruner],
  queues: [default: 10]

# Configures the endpoint
config :algora, AlgoraWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "H04mI/fsBvjCX3HO+P2bxFEM7PG3SaGTV+DE1f/BbTVG9oiOXSXsq+3tjDXxRXSe",
  pubsub_server: Algora.PubSub,
  live_view: [signing_salt: "fMm4VTD0Mkn/AB41KV+GwgofkocpAGOf"],
  render_errors: [
    formats: [html: AlgoraWeb.ErrorHTML, json: AlgoraWeb.ErrorJSON],
    layout: false
  ]

config :esbuild,
  version: "0.12.18",
  default: [
    args: ~w(js/app.js --bundle --target=es2016 --outdir=../priv/static/assets),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.1.8",
  default: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
