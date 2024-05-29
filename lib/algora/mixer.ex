defmodule Algora.Mixer do
  use Membrane.Filter

  def_input_pad(:input,
    availability: :on_request,
    flow_control: :auto,
    accepted_format: _any
  )

  def_output_pad(:output,
    availability: :on_request,
    flow_control: :push,
    accepted_format: _any
  )

  @impl true
  def handle_init(_ctx, _opts) do
    {[], %{accepted_format: nil}}
  end

  @impl true
  def handle_stream_format(Pad.ref(:output, _ref), accepted_format, _ctx, state) do
    {[forward: accepted_format], %{state | accepted_format: accepted_format}}
  end

  def handle_stream_format(Pad.ref(:input, _ref), accepted_format, _ctx, state) do
    {[forward: accepted_format], %{state | accepted_format: accepted_format}}
  end

  @impl true
  def handle_pad_added(Pad.ref(:input, _ref), _ctx, %{accepted_format: nil} = state) do
    {[], state}
  end

  @impl true
  def handle_pad_added(
        Pad.ref(:input, _ref) = _pad,
        _ctx,
        %{accepted_format: _accepted_format} = state
      ) do
    {[], state}
    # {[stream_format: {pad, accepted_format}], state}
  end

  @impl true
  def handle_pad_added(Pad.ref(:output, _ref), _ctx, %{accepted_format: nil} = state) do
    {[], state}
  end

  @impl true
  def handle_pad_added(
        Pad.ref(:output, _ref) = pad,
        _ctx,
        %{accepted_format: accepted_format} = state
      ) do
    {[stream_format: {pad, accepted_format}], state}
  end

  @impl true
  def handle_buffer(Pad.ref(:input, _ref), buffer, _ctx, state) do
    {[forward: buffer], state}
  end

  @impl true
  def handle_end_of_stream(_pad, _ctx, _state) do
    {[], %{accepted_format: nil}}
  end
end
