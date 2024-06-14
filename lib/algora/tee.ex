defmodule Algora.Tee do
  @moduledoc """
  Element for forwarding buffers to at least one output pad

  It has one input pad `:input` and 2 output pads:
  * `:master` - is a static pad which is always available and works in pull mode
  * `:copy` - is a dynamic pad that can be linked to any number of elements (including 0) and works in push mode

  The `:master` pad dictates the speed of processing data and any element (or elements) connected to `:copy` pad
  will receive the same data as `:master`
  """
  use Membrane.Filter

  def_input_pad(:input,
    availability: :always,
    flow_control: :auto,
    accepted_format: _any
  )

  def_output_pad(:master,
    availability: :always,
    flow_control: :auto,
    accepted_format: _any
  )

  def_output_pad(:copy,
    availability: :on_request,
    flow_control: :push,
    accepted_format: _any
  )

  @impl true
  def handle_init(_ctx, _opts) do
    {[], %{accepted_format: nil, count: 0}}
  end

  @impl true
  def handle_stream_format(_pad, accepted_format, _ctx, state) do
    {[forward: accepted_format], %{state | accepted_format: accepted_format}}
  end

  @impl true
  def handle_pad_added(Pad.ref(:copy, _ref), _ctx, %{accepted_format: nil} = state) do
    {[], state}
  end

  @impl true
  def handle_pad_added(
        Pad.ref(:copy, _ref) = pad,
        _ctx,
        %{accepted_format: accepted_format} = state
      ) do
    dbg({:tee, :actions, [stream_format: {pad, accepted_format}]})
    {[stream_format: {pad, accepted_format}], state}
  end

  @impl true
  def handle_buffer(:input, %Membrane.Buffer{} = buffer, _ctx, state) do
    # state =
    #   if state.count < 10 do
    #     dbg(buffer)
    #     %{state | count: state.count + 1}
    #   else
    #     state
    #   end

    {[forward: buffer], state}
  end

  @impl true
  def handle_start_of_stream(pad, _ctx, state) do
    dbg({:tee, :handle_start_of_stream, pad})
    {[], state}
  end
end
