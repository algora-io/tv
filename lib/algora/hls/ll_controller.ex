defmodule Algora.HLS.LLController do
  use GenServer

  @pubsub Algora.PubSub

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  @impl true
  def init(opts) do
    Phoenix.PubSub.subscribe(@pubsub, topic(opts.video_uuid))
    {:ok, opts}
  end

  @impl true
  def handle_info({module, function, args}, state) do
    res = apply(module, function, args)
    dbg(res)
    {:noreply, state}
  end

  def broadcast!(topic, {_module, _function, _args} = msg) do
    Phoenix.PubSub.broadcast!(@pubsub, topic, msg)
  end

  def topic(video_uuid), do: "stream:#{video_uuid}"
end
