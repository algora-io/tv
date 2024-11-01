defmodule Algora.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    topologies = Application.get_env(:libcluster, :topologies) || []
    flame_parent = FLAME.Parent.get()

    tcp_server_options = %{
      port: Algora.config([:rtmp_port]),
      listen_options: [
        :binary,
        packet: :raw,
        active: false,
        ip: {0, 0, 0, 0}
      ],
      handle_new_client: &Algora.Pipeline.Manager.handle_new_client/3
    }

    :ok = :syn.add_node_to_scopes([:pipelines])

    children = [
      Algora.Env,
      {Cluster.Supervisor, [topologies, [name: Algora.ClusterSupervisor]]},
      {Task.Supervisor, name: Algora.TaskSupervisor},
      # Start the supervisor for tracking manifest uploads
      {DynamicSupervisor, strategy: :one_for_one, name: Algora.Pipeline.Storage.ManifestSupervisor},
      # Start the RPC server
      {Fly.RPC, []},
      # Start the Ecto repository
      Algora.Repo.Local,
      # Start the supervisor for LSN tracking
      {Fly.Postgres.LSN.Supervisor, repo: Algora.Repo.Local},
      # Start the Oban system
      {Oban, Application.fetch_env!(:algora, Oban)},
      # Start the Telemetry supervisor
      AlgoraWeb.Telemetry,
      # Pipeline flame pool
      {FLAME.Pool,
        name: Algora.Pipeline.Pool,
        backend: Algora.config([:flame_backend]),
        min: Algora.config([:flame, :min]),
        max: Algora.config([:flame, :max]),
        max_concurrency: Algora.config([:flame, :max_concurrency]),
        idle_shutdown_after: Algora.config([:flame, :idle_shutdown_after]),
        log: Algora.config([:flame, :log]),
      },
      # Start the PubSub system
      {Phoenix.PubSub, name: Algora.PubSub},
      # Start presence
      AlgoraWeb.Presence,
      {Finch, name: Algora.Finch},
      # Clustering setup
      {DNSCluster, query: Application.get_env(:algora, :dns_cluster_query) || :ignore},
      # Start the Endpoints (http/https)
      !flame_parent && AlgoraWeb.Endpoint,
      !flame_parent && AlgoraWeb.Embed.Endpoint,
      # Start the LL-HLS controller registry
      {Registry, keys: :unique, name: Algora.LLControllerRegistry},
      # Start the RTMP server
      %{
        id: Membrane.RTMPServer,
        start: {Membrane.RTMPServer, :start_link, [tcp_server_options]}
      },
      !flame_parent && Algora.Stargazer,
      Algora.Terminate,
      ExMarcel.TableWrapper,
      Algora.Youtube.Chat.Supervisor
      # Start a worker by calling: Algora.Worker.start_link(arg)
      # {Algora.Worker, arg}
    ] |> Enum.filter(& &1)

    :ets.new(:videos_to_tables, [:public, :set, :named_table])
    :ets.new(:videos_to_folder_paths, [:public, :set, :named_table])

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Algora.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    AlgoraWeb.Endpoint.config_change(changed, removed)
    AlgoraWeb.Embed.Endpoint.config_change(changed, removed)
    :ok
  end
end
