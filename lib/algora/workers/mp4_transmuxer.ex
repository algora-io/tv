defmodule Algora.Workers.Mp4Transmuxer do
  use Oban.Worker, queue: :default, max_attempts: 3, unique: [period: 86_400]

  alias Algora.Library
  import Ecto.Query, warn: false

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"video_id" => video_id}}) do
    video_id
    |> Library.get_video!()
    |> Library.transmux_to_mp4()
  end
end
