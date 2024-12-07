import Config

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.

if System.get_env("PHX_SERVER") && System.get_env("RELEASE_NAME") do
  config :algora, AlgoraWeb.Endpoint, server: true
  config :algora, AlgoraWeb.Embed.Endpoint, server: true
end

transcode_backend = case System.get_env("MIX_TARGET") do
  "nvidia" -> Membrane.ABRTranscoder.Backends.Nvidia
  "xilinx" -> Membrane.ABRTranscoder.Backends.U30
   _ -> nil
end

flame_backend = case System.get_env("FLAME_BACKEND") do
  "fly" -> FLAME.FlyBackend
  _ -> FLAME.LocalBackend
end

config :algora,
  hf_token: System.get_env("HF_TOKEN"),
  resume_rtmp: System.get_env("RESUME_RTMP") == "true",
  resume_rtmp_on_unpublish: System.get_env("RESUME_RTMP_ON_UNPUBLUSH") == "true",
  resume_rtmp_timeout: System.get_env("RESUME_RTMP_TIMEOUT", "3200"),
  supports_h265: System.get_env("SUPPORTS_H265") == "true",
  transcode: (case System.get_env("TRANSCODE") do
    "" -> nil
    other -> other
  end),
  transcode_include_master: System.get_env("TRANSCODE_INCLUDE_MASTER", "false") == "true",
  transcode_backend: transcode_backend,
  flame_backend: flame_backend,
  rtmp_port: String.to_integer(System.get_env("RTMP_PORT", "9006"))

config :replicate,
  replicate_api_token: System.get_env("REPLICATE_API_TOKEN")

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
    # ssl: true,
    priv: "priv/repo",
    socket_options: if(ecto_ipv6?, do: [:inet6], else: []),
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")

  unless Fly.RPC.is_primary?() do
    config :algora, Oban,
      queues: false,
      plugins: false,
      peer: false
  end

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

  config :algora, AlgoraWeb.Embed.Endpoint,
    url: [host: host, port: 444, scheme: "https"],
    http: [
      # Enable IPv6 and bind on all interfaces.
      # Set it to  {0, 0, 0, 0, 0, 0, 0, 1} for local network only access.
      # See the documentation on https://hexdocs.pm/plug_cowboy/Plug.Cowboy.html
      # for details about using IPv6 vs IPv4 and loopback vs public addresses.
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: "4001"
    ],
    secret_key_base: secret_key_base

  config :algora, :buckets,
    media: System.get_env("BUCKET_MEDIA"),
    ml: System.get_env("BUCKET_ML")

  config :algora, :github,
    client_id: System.fetch_env!("GITHUB_CLIENT_ID"),
    client_secret: System.fetch_env!("GITHUB_CLIENT_SECRET")

  config :algora, :restream,
    client_id: System.fetch_env!("RESTREAM_CLIENT_ID"),
    client_secret: System.fetch_env!("RESTREAM_CLIENT_SECRET")

  config :algora, :event_sink, url: System.get_env("EVENT_SINK_URL")

  config :algora, :flame,
    backend: flame_backend,
    min: String.to_integer(System.get_env("FLAME_MIN", "0")),
    max: String.to_integer(System.get_env("FLAME_MAX", "1")),
    max_concurrency: String.to_integer(System.get_env("FLAME_MAX_CONCURRENCY", "10")),
    idle_shutdown_after: String.to_integer(System.get_env("FLAME_IDLE_SHUTDOWN_AFTER", "30")),
    log: System.get_env("FLAME_LOG", "debug")

  config :ex_aws,
    json_codec: Jason,
    access_key_id: System.fetch_env!("AWS_ACCESS_KEY_ID"),
    secret_access_key: System.fetch_env!("AWS_SECRET_ACCESS_KEY")

  config :ex_aws, :s3,
    scheme: "https://",
    host: URI.parse(System.fetch_env!("AWS_ENDPOINT_URL_S3")).host,
    region: System.fetch_env!("AWS_REGION")

  config :ex_aws, :hackney_opts,
    timeout: 300_000,
    recv_timeout: 300_000

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

    # https://hexdocs.pm/flame/FLAME.FlyBackend.html
    config :flame, FLAME.FlyBackend,
#     cpu_kind: "performance", # The size of the runner CPU. Defaults to "performance".
#     cpus: 2, # The number of runner CPUs. Defaults to System.schedulers_online() for the number of cores of the running parent app.
#     memory_mb: 4096, # The memory of the runner. Must be a 1024 multiple. Defaults to 4096.
#     gpu_kind: "L40S", # The type of GPU reservation to make.
#     gpus: 1, # The number of runner GPUs. Defaults to 1 if :gpu_kind is set.
#     boot_timeout: 30_000, # The boot timeout. Defaults to 30_000.
#     app: "", #  The name of the otp app. Defaults to System.get_env("FLY_APP_NAME"),
#     image: "", #  The URL of the docker image to pass to the machines create endpoint. Defaults to System.get_env("FLY_IMAGE_REF") which is the image of your running app.
#     token: "", #  The Fly API token. Defaults to System.get_env("FLY_API_TOKEN").
#     host: "", #  The host of the Fly API. Defaults to "https://api.machines.dev".
#     init: %{ #  The init object to pass to the machines create endpoint. Defaults to %{}. Possible values include:
#       cmd: "", #  list of strings for the command
#       entrypoint: "", #  list strings for the entrypoint command
#       exec: "", #  list of strings for the exec command
#       kernel_args: "", # list of strings
#       swap_size_mb: "", #  integer value in megabytes for the swap size
#       tty: "", #  boolean
#     },
#     services: [], # The optional services to run on the machine. Defaults to [].
#     metadata: %{}, # The optional map of metadata to set for the machine. Defaults to %{}.
      env: %{
        "MIX_TARGET" => "nvidia",
        "AWS_ACCESS_KEY_ID" => System.get_env("AWS_ACCESS_KEY_ID"),
        "AWS_ENDPOINT_URL_S3" => System.get_env("AWS_ENDPOINT_URL_S3"),
        "AWS_IGNORE_CONFIGURED_ENDPOINT_URLS" => System.get_env("AWS_IGNORE_CONFIGURED_ENDPOINT_URLS"),
        "AWS_REGION" => System.get_env("AWS_REGION"),
        "AWS_SECRET_ACCESS_KEY" => System.get_env("AWS_SECRET_ACCESS_KEY"),
        "BUCKET_MEDIA" => System.get_env("BUCKET_MEDIA"),
        "BUCKET_ML" => System.get_env("BUCKET_ML"),
        "DATABASE_URL" => System.get_env("DATABASE_URL"),
        "EVENT_SINK_URL" => System.get_env("EVENT_SINK_URL"),
       # GITHUB_CLIENT_ID" => System.get_env("GITHUB_CLIENT_ID"),
       # GITHUB_CLIENT_SECRET" => System.get_env("GITHUB_CLIENT_SECRET"),
        "HF_TOKEN" => System.get_env("HF_TOKEN"),
        "REPLICATE_API_TOKEN" => System.get_env("REPLICATE_API_TOKEN"),
        "RESUME_RTMP" => System.get_env("RESUME_RTMP"),
        "SECRET_KEY_BASE" => System.get_env("SECRET_KEY_BASE"),
        "SUPPORTS_H265" => System.get_env("SUPPORTS_H265"),
        "TEST_BUCKET_MEDIA" => System.get_env("TEST_BUCKET_MEDIA"),
        "TEST_BUCKET_ML" => System.get_env("TEST_BUCKET_ML"),
        "TEST_DATABASE_URL" => System.get_env("TEST_DATABASE_URL"),
        "TRANSCODE" => System.get_env("TRANSCODE"),
      }
end
