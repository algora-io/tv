defmodule Algora.Workers.HLSTransmuxer do
  use Oban.Worker, queue: :default, max_attempts: 3, unique: [period: 86_400]

  alias Algora.Library
  import Ecto.Query, warn: false

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"video_id" => video_id}}) do
    video = Library.get_video!(video_id)
    build_transmuxer(video)
    await_transmuxer(video)
  end

  defp build_transmuxer(%Library.Video{} = video) do
    job_pid = self()

    Task.async(fn ->
      mp4_video =
        Library.transmux_to_hls(video, fn progress ->
          send(job_pid, {:progress, progress})
        end)

      send(job_pid, {:complete, mp4_video})
    end)
  end

  defp await_transmuxer(video, done \\ 0) do
    receive do
      {:progress, %{done: done_now, total: total}} ->
        Library.broadcast_transmuxing_progressed!(video, min(1, done / total))
        await_transmuxer(video, done + done_now)

      {:complete, %Library.Video{url: url}} ->
        Library.broadcast_transmuxing_progressed!(video, 1)
        Library.broadcast_transmuxing_completed!(video, url)
        :ok
    end
  end
end
