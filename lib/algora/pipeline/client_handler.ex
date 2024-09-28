defmodule Algora.Pipeline.ClientHandler do
  @moduledoc """
  An implementation of `Membrane.RTMPServer.ClienHandlerBehaviour` compatible with the
  `Membrane.RTMP.Source` element.
  """

  require Membrane.Logger

  @behaviour Membrane.RTMPServer.ClientHandler

  defstruct []

  @impl true
  def handle_init(_opts) do
    %{
      source_pid: nil,
      buffered: []
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
  def handle_end_of_stream(state) do
    if state.source_pid != nil, do: send_eos(state.source_pid)
    state
  end

  defp send_data(pid, payload) do
    send(pid, {:data, payload})
    :ok
  end

  defp send_eos(pid) do
    send(pid, :end_of_stream)
    :ok
  end
end
