import Config

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.

if System.get_env("PHX_SERVER") && System.get_env("RELEASE_NAME") do
  config :algora, AlgoraWeb.Endpoint, server: true
end

if config_env() == :prod do
  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      """

  host = System.get_env("PHX_HOST") || "example.com"
  ecto_ipv6? = System.get_env("ECTO_IPV6") == "true"

  app_name =
    System.get_env("FLY_APP_NAME") ||
      raise "FLY_APP_NAME not available"

  config :algora, dns_cluster_query: System.get_env("DNS_CLUSTER_QUERY")

  config :algora, Algora.Repo,
    # ssl: true,
    socket_options: if(ecto_ipv6?, do: [:inet6], else: []),
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")

  config :algora, Algora.Repo.Local,
    socket_options: if(ecto_ipv6?, do: [:inet6], else: []),
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
    priv: "priv/repo"

  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  config :algora, AlgoraWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [
      # Enable IPv6 and bind on all interfaces.
      # Set it to  {0, 0, 0, 0, 0, 0, 0, 1} for local network only access.
      # See the documentation on https://hexdocs.pm/plug_cowboy/Plug.Cowboy.html
      # for details about using IPv6 vs IPv4 and loopback vs public addresses.
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: String.to_integer(System.get_env("PORT") || "4000")
    ],
    secret_key_base: secret_key_base

  config :algora, :files, bucket: System.fetch_env!("BUCKET_NAME")

  config :algora, :github,
    client_id: System.fetch_env!("GITHUB_CLIENT_ID"),
    client_secret: System.fetch_env!("GITHUB_CLIENT_SECRET")

  config :algora, :event_sink, url: System.get_env("EVENT_SINK_URL")

  config :ex_aws,
    json_codec: Jason,
    access_key_id: System.fetch_env!("AWS_ACCESS_KEY_ID"),
    secret_access_key: System.fetch_env!("AWS_SECRET_ACCESS_KEY")

  config :ex_aws, :s3,
    scheme: "https://",
    host: URI.parse(System.fetch_env!("AWS_ENDPOINT_URL_S3")).host,
    region: System.fetch_env!("AWS_REGION")

  config :libcluster,
    topologies: [
      fly6pn: [
        strategy: Cluster.Strategy.DNSPoll,
        config: [
          polling_interval: 5_000,
          query: "#{app_name}.internal",
          node_basename: app_name
        ]
      ]
    ]
end
