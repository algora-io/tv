defmodule Algora.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    topologies = Application.get_env(:libcluster, :topologies) || []

    tcp_server_options = %Membrane.RTMP.Source.TcpServer{
      port: Algora.config([:rtmp_port]),
      listen_options: [
        :binary,
        packet: :raw,
        active: false,
        ip: {0, 0, 0, 0}
      ],
      socket_handler: fn socket ->
        if pid = Membrane.Pipeline.list_pipelines() |> Enum.at(0) do
          dbg("routing to existing pipeline #{:erlang.pid_to_list(pid)}")
          send(pid, {:new_conn, socket})
          {:ok, pid}
        else
          {:ok, _sup, pid} =
            Membrane.Pipeline.start_link(Algora.Pipeline, socket: socket)

          dbg("routing to new pipeline #{:erlang.pid_to_list(pid)}")
          {:ok, pid}
        end
      end
    }

    children = [
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
      # Start the RTMP server
      %{
        id: Membrane.RTMP.Source.TcpServer,
        start: {Membrane.RTMP.Source.TcpServer, :start_link, [tcp_server_options]}
      },
      Algora.Stargazer,
      ExMarcel.TableWrapper
      # Start a worker by calling: Algora.Worker.start_link(arg)
      # {Algora.Worker, arg}
    ]

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
