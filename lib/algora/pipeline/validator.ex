defmodule Algora.Pipeline.MessageValidator do
  defstruct [:video_id, :pid]
end

defimpl Membrane.RTMP.MessageValidator, for: Algora.Pipeline.MessageValidator do
  alias Membrane.RTMP.Messages

  @app_name Algora.config([:rtmp_path])

  @impl true
  def validate_connect(_impl, %Messages.Connect{app: @app_name}), do:
    {:ok, "connected"}
  def validate_connect(impl, %Messages.Connect{app: stream_key}) do
    # allow url based stream keys to work
    GenServer.call(impl.pid, {:validate_stream_key, stream_key})
  end

  @impl true
  def validate_release_stream(impl, %Messages.ReleaseStream{stream_key: stream_key}) do
    GenServer.call(impl.pid, {:validate_stream_key, stream_key})
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
