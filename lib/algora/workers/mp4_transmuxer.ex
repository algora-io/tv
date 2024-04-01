defmodule Algora.Workers.MP4Transmuxer do
  use Oban.Worker, queue: :default, max_attempts: 3, unique: [period: 86_400]

  alias Algora.Library
  import Ecto.Query, warn: false

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"video_id" => video_id}} = job) do
    video = Library.get_video!(video_id)
    build_transmuxer(job, video)
    await_transmuxer(video)
  end

  defp build_transmuxer(job, %Library.Video{} = video) do
    job_pid = self()

    Task.async(fn ->
      try do
        mp4_video =
          Library.transmux_to_mp4(video, fn progress ->
            send(job_pid, {:progress, progress})
          end)

        send(job_pid, {:complete, mp4_video})
      rescue
        e ->
          send(job_pid, {:error, e, job})
          reraise e, __STACKTRACE__
      end
    end)
  end

  defp await_transmuxer(video, stage \\ :retrieving, done \\ 0) do
    receive do
      {:progress, %{stage: stage_now, done: done_now, total: total}} ->
        Library.broadcast_processing_progressed!(stage, video, min(1, done / total))
        done_total = if(stage == stage_now, do: done, else: 0)
        await_transmuxer(video, stage_now, done_total + done_now)

      {:complete, %Library.Video{url: url}} ->
        Library.broadcast_processing_progressed!(stage, video, 1)
        Library.broadcast_processing_completed!(:download, video, url)
        {:ok, url}

      {:error, e, %Oban.Job{attempt: attempt, max_attempts: max_attempts}} ->
        Library.broadcast_processing_failed!(video, attempt, max_attempts)
        {:error, e}
    end
  end
end
