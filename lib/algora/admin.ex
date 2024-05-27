alias Algora.{Accounts, Library}

defmodule Algora.Admin do
  def set_thumbnail!(id, path) do
    video = Library.get_video!(id)
    {:ok, _} = Library.store_thumbnail_from_file(video, path || "/tmp/#{id}.png")
    {:ok, _} = Library.store_og_image_from_file(video, path || "/tmp/#{id}.png")
  end

  def set_title!(id, title) do
    video = Library.get_video!(id)
    user = Accounts.get_user!(video.user_id)
    {:ok, _} = Library.update_video(video, %{title: title})
    {:ok, _} = Accounts.update_settings(user, %{channel_tagline: title})
  end

  def pipelines() do
    Node.list() |> Enum.flat_map(&Membrane.Pipeline.list_pipelines/1)
  end

  def broadcasts() do
    pipelines() |> Enum.map(fn pid -> GenServer.call(pid, :get_video_id) end)
  end
end
