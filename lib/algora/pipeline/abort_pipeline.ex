defmodule Algora.Pipeline.AbortPipeline do
  use Membrane.Pipeline
  require Membrane.Logger

  def handle_init(_ctx, %{stream_key: stream_key, client_ref: client_ref} = params) do
    Membrane.Logger.error("Aborted stream key: #{stream_key}")
    spec = [
      #
      child(:abort, %Algora.Pipeline.SourceBin{
        client_ref: client_ref
      }),

      #
      get_child(:abort)
      |> via_out(:audio)
      |> child(:video, Membrane.Testing.Sink),

      #
      get_child(:abort)
      |> via_out(:video)
      |> child(:audio, Membrane.Testing.Sink),
    ]
    {[spec: spec, terminate: :normal], params}
  end
end

