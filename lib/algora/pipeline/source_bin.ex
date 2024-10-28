defmodule Algora.Pipeline.SourceBin do
  @moduledoc """
  Bin responsible for demuxing and parsing an RTMP stream.

  Outputs single audio and video which are ready for further processing with Membrane Elements.
  At this moment only AAC and H264 codecs are supported.

  The bin can be used in the following two scenarios:
  * by providing the URL on which the client is expected to connect - note, that if the client doesn't
  connect on this URL, the bin won't complete its setup
  * by spawning `Membrane.RTMPServer`, receiving client reference after client connects on a given `app` and `stream_key`
  and passing the client reference to the `#{inspect(__MODULE__)}`.
  """
  use Membrane.Bin

  alias Membrane.{AAC, H264, RTMP}

  def_output_pad :video,
    accepted_format: H264,
    availability: :on_request

  def_output_pad :audio,
    accepted_format: AAC,
    availability: :on_request

  def_options client_ref: [
                default: nil,
                spec: pid(),
                description: """
                A pid of a process acting as a client reference.
                Can be gained with the use of `Membrane.RTMPServer`.
                """
              ],
              url: [
                default: nil,
                spec: String.t(),
                description: """
                An URL on which the client is expected to connect, for example:
                rtmp://127.0.0.1:1935/app/stream_key
                """
              ]

  @impl true
  def handle_init(_ctx, %__MODULE__{} = opts) do
    spec =
      child(:src, %RTMP.Source{
        client_ref: opts.client_ref,
        url: opts.url
      })
      |> child(:demuxer, Membrane.FLV.Demuxer)

    state = %{
      demuxer_audio_pad_ref: nil,
      demuxer_video_pad_ref: nil,
      client_ref: opts.client_ref,
    }

    {[spec: spec], state}
  end

  @impl true
  def handle_pad_added(Pad.ref(:audio, _ref) = pad, ctx, state) do
    assert_pad_count!(:audio, ctx)

    spec =
      child(:funnel_audio, Membrane.Funnel, get_if_exists: true)
      |> bin_output(pad)

    {actions, state} = maybe_link_audio_pad(state)

    {[spec: spec] ++ actions, state}
  end

  def handle_pad_added(Pad.ref(:video, _ref) = pad, ctx, state) do
    assert_pad_count!(:video, ctx)

    spec =
      child(:funnel_video, Membrane.Funnel, get_if_exists: true)
      |> bin_output(pad)

    {actions, state} = maybe_link_video_pad(state)

    {[spec: spec] ++ actions, state}
  end

  @impl true
  def handle_child_notification({:new_stream, pad_ref, :AAC}, :demuxer, _ctx, state) do
    maybe_link_audio_pad(%{state | demuxer_audio_pad_ref: pad_ref})
  end

  def handle_child_notification({:new_stream, pad_ref, :H264}, :demuxer, _ctx, state) do
    maybe_link_video_pad(%{state | demuxer_video_pad_ref: pad_ref})
  end

  def handle_child_notification(
        {type, _socket, _pid} = notification,
        :src,
        _ctx,
        state
      )
      when type in [:socket_control_needed, :ssl_socket_control_needed] do
    {[notify_parent: notification], state}
  end

  def handle_child_notification(
        {type, _stage, _reason} = notification,
        :src,
        _ctx,
        state
      )
      when type in [:stream_validation_success, :stream_validation_error] do
    {[notify_parent: notification], state}
  end

  def handle_child_notification(:stream_deleted, :src, _ctx, state) do
    {[notify_parent: :stream_deleted], state}
  end

  @doc """
  Passes the control of the socket to the `source`.

  To succeed, the executing process must be in control of the socket, otherwise `{:error, :not_owner}` is returned.
  """
  @spec pass_control(:gen_tcp.socket(), pid()) :: :ok | {:error, atom()}
  def pass_control(socket, source) do
    :gen_tcp.controlling_process(socket, source)
  end

  @doc """
  Passes the control of the ssl socket to the `source`.

  To succeed, the executing process must be in control of the socket, otherwise `{:error, :not_owner}` is returned.
  """
  @spec secure_pass_control(:ssl.sslsocket(), pid()) :: :ok | {:error, any()}
  def secure_pass_control(socket, source) do
    :ssl.controlling_process(socket, source)
  end

  defp maybe_link_audio_pad(state) when state.demuxer_audio_pad_ref != nil do
    {[
       spec:
         get_child(:demuxer)
         |> via_out(state.demuxer_audio_pad_ref)
         |> child(:audio_parser, %Membrane.AAC.Parser{
           out_encapsulation: :none
         })
         |> child(:funnel_audio, Membrane.Funnel, get_if_exists: true)
     ], state}
  end

  defp maybe_link_audio_pad(state) do
    {[], state}
  end

  defp maybe_link_video_pad(state) when state.demuxer_video_pad_ref != nil do
    {[
       spec:
         get_child(:demuxer)
         |> via_out(state.demuxer_video_pad_ref)
         |> child(:video_parser, Membrane.H264.Parser)
         |> child(:funnel_video, Membrane.Funnel, get_if_exists: true)
     ], state}
  end

  defp maybe_link_video_pad(state) do
    {[], state}
  end

  defp assert_pad_count!(name, ctx) do
    count =
      ctx.pads
      |> Map.keys()
      |> Enum.count(fn pad_ref -> Pad.name_by_ref(pad_ref) == name end)

    if count > 1 do
      raise(
        "Linking more than one #{inspect(name)} output pad to #{inspect(__MODULE__)} is not allowed"
      )
    end

    :ok
  end
end
