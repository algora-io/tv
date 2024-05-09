defmodule Algora.MessageValidator do
  defstruct [:video_id]
end

defimpl Membrane.RTMP.MessageValidator, for: Algora.MessageValidator do
  @impl true
  def validate_connect(_impl, _message) do
    {:ok, "connect success"}
  end

  @impl true
  def validate_release_stream(impl, message) do
    {:ok, video} =
      Algora.Library.reconcile_livestream(
        %Algora.Library.Video{id: impl.video_id},
        message.stream_key
      )

    Algora.Library.toggle_streamer_live(video, true)

    {:ok, "release stream success"}
  end

  @impl true
  def validate_publish(_impl, _message) do
    {:ok, "validate publish success"}
  end

  @impl true
  def validate_set_data_frame(_impl, _message) do
    {:ok, "set data frame success"}
  end
end
