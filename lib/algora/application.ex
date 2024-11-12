defmodule Algora.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    topologies = Application.get_env(:libcluster, :topologies) || []

    tcp_server_options = %{
      port: Algora.config([:rtmp_port]),
      listen_options: [
        :binary,
        packet: :raw,
        active: false,
        ip: {0, 0, 0, 0}
      ],
      handle_new_client: fn client_ref, app, stream_key ->
        params = %{
          client_ref: client_ref,
          app: app,
          stream_key: stream_key,
          video_uuid: nil,
          parent: self()
        }


        {:ok, _pid} = case Registry.lookup(Algora.Pipeline.Registry, stream_key) do
          [{pid, {:pipeline, video_uuid}}] ->
            Algora.Pipeline.resume_rtmp(pid, %{params | video_uuid: video_uuid})
            {:ok, pid}
          [] ->
            {:ok, _sup, pid} =
              Membrane.Pipeline.start_link(Algora.Pipeline, params)
            {:ok, pid}
        end

          {Algora.Pipeline.ClientHandler, %{}}
      end
    }

    children = [
      Algora.Env,
      {Cluster.Supervisor, [topologies, [name: Algora.ClusterSupervisor]]},
      {Task.Supervisor, name: Algora.TaskSupervisor},
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
      # Pipeline Registry
      {Registry, keys: :unique, name: Algora.Pipeline.Registry},
      # Start the PubSub system
      {Phoenix.PubSub, name: Algora.PubSub},
      # Start presence
      AlgoraWeb.Presence,
      {Finch, name: Algora.Finch},
      # Clustering setup
      {DNSCluster, query: Application.get_env(:algora, :dns_cluster_query) || :ignore},
      # Start the Endpoints (http/https)
      AlgoraWeb.Endpoint,
      AlgoraWeb.Embed.Endpoint,
      # Start the LL-HLS controller registry
      {Registry, keys: :unique, name: Algora.LLControllerRegistry},
      # Start the RTMP server
      %{
        id: Membrane.RTMPServer,
        start: {Membrane.RTMPServer, :start_link, [tcp_server_options]}
      },
      Algora.Stargazer,
      Algora.Terminate,
      ExMarcel.TableWrapper,
      Algora.Youtube.Chat.Supervisor
      # Start a worker by calling: Algora.Worker.start_link(arg)
      # {Algora.Worker, arg}
    ]

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
