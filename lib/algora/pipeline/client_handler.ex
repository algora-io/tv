defmodule Algora.Pipeline.ClientHandler do
  @moduledoc """
  An implementation of `Membrane.RTMPServer.ClienHandlerBehaviour` compatible with the
  `Membrane.RTMP.Source` element.
  """

  @behaviour Membrane.RTMPServer.ClientHandler

  defstruct []

  @impl true
  def handle_init(%{pipeline: pid}) do
    %{
      source_pid: nil,
      buffered: [],
      pipeline: pid
    }
  end

  @impl true
  def handle_info({:send_me_data, source_pid}, state) do
    buffers_to_send = Enum.reverse(state.buffered)
    state = %{state | source_pid: source_pid, buffered: []}
    Enum.each(buffers_to_send, fn buffer -> send_data(state.source_pid, buffer) end)
    state
  end

  @impl true
  def handle_info(_other, state) do
    state
  end

  @impl true
  def handle_data_available(payload, state) do
    if state.source_pid do
      :ok = send_data(state.source_pid, payload)
      state
    else
      %{state | buffered: [payload | state.buffered]}
    end
  end

  @impl true
  def handle_connection_closed(state) do
    if state.source_pid != nil, do: send(state.source_pid, :connection_closed)
    state
  end

  @impl true
  def handle_delete_stream(state) do
    if state.source_pid != nil, do: send(state.source_pid, :delete_stream)
    state
  end

  @impl true
  def handle_metadata(message, state) do
    send(state.pipeline, message)
    state
  end

  defp send_data(pid, payload) do
    send(pid, {:data, payload})
    :ok
  end
end
