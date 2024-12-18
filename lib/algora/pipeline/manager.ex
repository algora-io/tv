defmodule Algora.Pipeline.Manager do
  alias Algora.Pipeline.AbortPipeline

  use GenServer

  @app "live"

  def handle_new_client(client_ref, "", ""), do:
    handle_new_client(client_ref, @app, "")

  def handle_new_client(client_ref, stream_key, ""), do:
    handle_new_client(client_ref, @app, stream_key)

  def handle_new_client(client_ref, @app, stream_key) do
    params = %{
      client_ref: client_ref,
      app: @app,
      stream_key: stream_key,
      video_uuid: nil
    }

    {:ok, pid} =
      with true <- Algora.config([:resume_rtmp]),
           {pid, metadata} when is_pid(pid) <- :syn.lookup(:pipelines, stream_key) do
        case resume_rtmp(pid, %{params | video_uuid: metadata[:video_uuid]}) do
          :ok ->
            {:ok, pid}
          {:error, reason} ->
            {:ok, _sub, pid} = Membrane.Pipeline.start_link(AbortPipeline, params)
            {:ok, pid}
        end
    else
      _ ->
        if Algora.config([:flame, :backend]) == FLAME.LocalBackend do
          Algora.Pipeline.Supervisor.start_child([self(), params])
        else
          FLAME.place_child(Algora.Pipeline.Pool, {__MODULE__, [self(), params]})
        end
    end

    {Algora.Pipeline.ClientHandler, %{pipeline: pid}}
  end

  def resume_rtmp(pipeline, params) when is_pid(pipeline) do
    GenServer.call(pipeline, {:resume_rtmp, params})
  end

  def start_link([pid, initial]) do
    GenServer.start_link(__MODULE__, [pid, initial])
  end

  def init([parent_pid, params]) do
    Process.flag(:trap_exit, true)
    {:ok, _sup, pid} = Membrane.Pipeline.start_link(Algora.Pipeline, params)
    send(parent_pid, {:started, pid})
    {:ok, %{ pid: pid, params: params }}
  end

  def handle_info({:EXIT, _pid, reason}, state) do
    {:stop, reason, state}
  end

  def handle_info(message, state) do
    send(state.pid, message)
    {:noreply, state}
  end
end
