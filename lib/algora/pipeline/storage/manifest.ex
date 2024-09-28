defmodule Algora.Pipeline.Storage.Manifest do
  use GenServer, restart: :transient

  require Membrane.Logger

  @delta_suffix_regex ~r/_delta.m3u8$/
  @delay Algora.Pipeline.segment_duration() * 1000

  def start_link([video]) do
    GenServer.start_link(__MODULE__, video)
  end

  @impl true
  def init(video) do
    {:ok, %{video: video, timers: %{}}}
  end

  @impl true
  def handle_cast({:upload, name, contents, upload_opts}, %{timers: timers} = state) do
    if String.match?(name, @delta_suffix_regex) do
      {:noreply, state}
    else
      if timer_ref = timers[name] do
        {:ok, :cancel} = :timer.cancel(timer_ref)
      end

      {:ok, timer_ref} = :timer.send_after(@delay, {
        :upload_immediate, name, contents, upload_opts
      })

      timers = Map.put(state.timers, name, timer_ref)
      {:noreply, %{state | timers: timers }}
    end
  end

  @impl true
  def handle_info({:upload_immediate, name, contents, upload_opts}, state) do
    path = "#{state.video.uuid}/#{name}"
    with {:ok, _} <- Algora.Storage.upload(contents, path, upload_opts) do
      Membrane.Logger.info("Uploaded manifest #{path}")
    else
      err ->
        Membrane.Logger.error("Failed to upload #{path}: #{err}")
    end

    timers = Map.delete(state.timers, name)
    {:noreply, %{ state | timers: timers }}
  end
end
