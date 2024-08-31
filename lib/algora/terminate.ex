defmodule Algora.Terminate do
  use GenServer

  @terminate_interval :timer.hours(1)

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @impl true
  def init(state) do
    schedule_terminate()
    {:ok, state}
  end

  @impl true
  def handle_info(:terminate, state) do
    Algora.Library.terminate_interrupted_streams()
    schedule_terminate()
    {:noreply, state}
  end

  defp schedule_terminate() do
    Process.send_after(self(), :terminate, @terminate_interval)
  end
end
