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
    Process.flag(:trap_exit, true)
    {:ok, %{video: video, manifests: %{}}}
  end

  @impl true
  def handle_cast({:upload, name, contents, upload_opts}, %{manifests: manifests} = state) do
    if String.match?(name, @delta_suffix_regex) do
      {:noreply, state}
    else
      with {timer_ref, _upload} <- manifests[name] do
        {:ok, :cancel} = :timer.cancel(timer_ref)
      end

      {:ok, timer_ref} = :timer.send_after(@delay, {
        :upload_immediate, name,
      })

      manifests = Map.put(state.manifests, name, {timer_ref, {contents, upload_opts}})
      {:noreply, %{state | manifests: manifests }}
    end
  end

  @impl true
  def handle_info({:upload_immediate, name}, state) do
    state = with {_timer, {contents, upload_opts}} <- state.manifests[name] do
      {:ok, state} = upload!(name, contents, upload_opts, state)
      state
    else
      _ -> state
    end

    {:noreply, state}
  end

  def handle_info({:EXIT, _pid, reason}, state) do
    {:stop, reason, state}
  end

  @impl true
  def terminate(reason, state) do
    Membrane.Logger.info("#{__MODULE__} terminating because of #{inspect(reason)}")
    Enum.all?(state.manifests, fn({name, {_timer, {contents, upload_opts}}}) ->
      {:ok, _state} = upload!(name, contents, upload_opts, state)
      true
    end) && :ok
  end

  defp upload!(name, contents, upload_opts, state) do
    path = "#{state.video.uuid}/#{name}"
    manifests = with {:ok, _} <- Algora.Storage.upload(contents, path, upload_opts) do
      Membrane.Logger.info("Uploaded manifest #{path}")
      Map.delete(state.manifests, name)
    else
      err ->
        Membrane.Logger.error("Failed to upload #{path}: #{inspect(err)}")
        state.manifests
    end


    {:ok, %{ state | manifests: manifests }}
  end
end
