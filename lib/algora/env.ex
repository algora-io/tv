defmodule Algora.Env do
  require Logger
  use GenServer

  def start_link(state) do
    GenServer.start_link(__MODULE__, Map.merge(%{transcode?: false}, Map.new(state)),
      name: __MODULE__
    )
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_call({:update, values}, _from, state) do
    {:reply, :ok, state |> Map.merge(Map.new(values))}
  end

  @impl true
  def handle_call(:list, _from, state) do
    {:reply, state, state}
  end

  def handle_call({:get, key}, _from, state) do
    {:reply, state |> Map.get(key), state}
  end

  def list() do
    GenServer.call(__MODULE__, :list)
  end

  def update(values) do
    GenServer.call(__MODULE__, {:update, values})
  end

  def get(key) do
    GenServer.call(__MODULE__, {:get, key})
  end
end
