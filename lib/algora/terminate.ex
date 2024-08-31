defmodule Algora.Terminate do
  use GenServer

  import Ecto.Query, warn: false

  @terminate_interval :timer.se(10)

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
    from(v in Algora.Library.Video,
          where: v.duration == 0 and v.is_live == false,
          select: v.id
        )
        |> Algora.Repo.Local.all
        |> Enum.each(&Algora.Library.terminate_stream/1)

    schedule_terminate()
    {:noreply, state}
  end

  defp schedule_terminate() do
    Process.send_after(self(), :terminate, @terminate_interval)
  end
end
