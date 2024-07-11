# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :algora,
  title: "Algora TV",
  description:
    "Algora TV is an interactive livestreaming & video sharing service for developers.",
  admin_emails: ["zafer@algora.io", "ioannis@algora.io"],
  ecto_repos: [Algora.Repo.Local],
  rtmp_port: 9006

# dispatch = [
#   _: [
#     {"/chat", AlgoraWeb.ChatSocket, []},
#     {:_, Phoenix.Endpoint.Cowboy2Handler, {AlgoraWeb.Endpoint, []}}
#   ]
# ]

# dispatch = [
#   {:_,
#    [
#      {"/chat", AlgoraWeb.ChatSocket, []},
#      {:_, Plug.Cowboy.Handler, {AlgoraWeb.Endpoint, []}}
#    ]}
# ]

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

# http: [dispatch: dispatch],
# https: [dispatch: dispatch]

config :algora, AlgoraWeb.Embed.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "H04mI/fsBvjCX3HO+P2bxFEM7PG3SaGTV+DE1f/BbTVG9oiOXSXsq+3tjDXxRXSe",
  pubsub_server: Algora.PubSub,
  live_view: [signing_salt: "fMm4VTD0Mkn/AB41KV+GwgofkocpAGOf"],
  render_errors: [
    formats: [html: AlgoraWeb.ErrorHTML, json: AlgoraWeb.ErrorJSON],
    layout: false
  ]

config :algora, Oban,
  repo: Algora.Repo.Local,
  queues: [default: 10]

config :esbuild,
  version: "0.17.11",
  tv: [
    args:
      ~w(js/app.ts --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.4.0",
  tv: [
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

config :nx, default_backend: EXLA.Backend

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
