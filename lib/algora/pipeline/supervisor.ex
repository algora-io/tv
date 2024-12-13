defmodule Algora.Pipeline.Supervisor do
  use DynamicSupervisor

  def resume_rtmp(pipeline, params) when is_pid(pipeline) do
    GenServer.call(pipeline, {:resume_rtmp, params})
  end

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  def start_child(init_arg) do
    spec = Supervisor.child_spec({Algora.Pipeline.Manager, init_arg}, restart: :transient)
    DynamicSupervisor.start_child(__MODULE__, spec)
  end

  @impl true
  def init(init_arg) do
    DynamicSupervisor.init(strategy: :simple_one_for_one, extra_arguments: [init_arg])
  end
end
