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

  def terminate_interrupted_streams() do
    # List all pipelines
    pipelines = Membrane.Pipeline.list_pipelines()

    # Check if there are any running livestreams
    livestreams_running = Enum.any?(pipelines, fn pid ->
      GenServer.call(pid, :get_video_id) != nil
    end)

    # If no livestreams are running, destroy old machines
    unless livestreams_running do
      # Logic to destroy old machines
      # This is a placeholder, replace with actual logic to destroy old machines
      IO.puts("Destroying old machines...")
    end
  end
end
