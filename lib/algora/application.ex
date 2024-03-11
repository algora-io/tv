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
        ip: {0, 0, 0, 0, 0, 0, 0, 0}
      ],
      socket_handler: fn socket ->
        {:ok, _sup, pid} =
          Membrane.Pipeline.start_link(Algora.Pipeline, socket: socket)

        {:ok, pid}
      end
    }

    children = [
      {Cluster.Supervisor, [topologies, [name: Algora.ClusterSupervisor]]},
      {Task.Supervisor, name: Algora.TaskSupervisor},
      # Start the Ecto repository
      Algora.Repo,
      Algora.ReplicaRepo,
      # Start the Telemetry supervisor
      AlgoraWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Algora.PubSub},
      # Start presence
      AlgoraWeb.Presence,
      {Finch, name: Algora.Finch},
      # Start the Endpoint (http/https)
      AlgoraWeb.Endpoint,
      # Start the RTMP server
      %{
        id: Membrane.RTMP.Source.TcpServer,
        start: {Membrane.RTMP.Source.TcpServer, :start_link, [tcp_server_options]}
      }

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
    :ok
  end
end
