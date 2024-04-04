defmodule Algora.Workers.Transcriber do
  use Oban.Worker, queue: :default, max_attempts: 1, unique: [period: 86_400]

  alias Algora.Library
  import Ecto.Query, warn: false

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"video_id" => video_id}} = job) do
    video = Library.get_video!(video_id)
    build_transcriber(job, video)
    await_transcriber(video)
  end

  defp build_transcriber(job, %Library.Video{} = video) do
    job_pid = self()

    Task.async(fn ->
      try do
        prediction =
          Library.transcribe_video(video, fn progress ->
            send(job_pid, {:progress, progress})
          end)

        output =
          await_prediction(prediction.id, fn progress ->
            send(job_pid, {:progress, progress})
          end)

        dbg(output)

        send(job_pid, {:complete, video})
      rescue
        e ->
          send(job_pid, {:error, e, job})
          reraise e, __STACKTRACE__
      end
    end)
  end

  defp await_prediction(id, cb) do
    case Replicate.Predictions.get(id) do
      {:ok, %Replicate.Predictions.Prediction{status: "succeeded", output: output}} ->
        {:ok, resp} = Finch.build(:get, output) |> Finch.request(Algora.Finch)
        Jason.decode!(resp.body)

      {:ok, %Replicate.Predictions.Prediction{logs: logs}} ->
        cb.(%{stage: logs |> String.split("\n") |> Enum.at(-1), done: 1, total: 1})
        :timer.sleep(1000)
        await_prediction(id, cb)

      error ->
        error
    end
  end

  defp await_transcriber(video, stage \\ :retrieving, done \\ 0) do
    receive do
      {:progress, %{stage: stage_now, done: done_now, total: total}} ->
        Library.broadcast_processing_progressed!(stage, video, min(1, done / total))
        done_total = if(stage == stage_now, do: done, else: 0)
        await_transcriber(video, stage_now, done_total + done_now)

      {:complete, video} ->
        Library.broadcast_processing_progressed!(stage, video, 1)
        Library.broadcast_processing_completed!(:transcription, video, video.url)
        {:ok, video.url}

      {:error, e, %Oban.Job{attempt: attempt, max_attempts: max_attempts}} ->
        Library.broadcast_processing_failed!(video, attempt, max_attempts)
        {:error, e}
    end
  end
end
