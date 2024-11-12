defmodule Algora.Pipeline do
  use Membrane.Pipeline

  alias Membrane.Time

  alias Algora.{Admin, Library}
  alias Algora.Pipeline.HLS.LLController

  @segment_duration_seconds 6
  @segment_duration Time.seconds(@segment_duration_seconds)
  @partial_segment_duration Time.milliseconds(200)
  @app "live"
  @terminate_after 60_000

  defstruct [
    client_ref: nil,
    stream_key: nil,
    user: nil,
    video: nil,
    dir: nil,
    reconnect: 0,
    terminate_timer: nil
  ]

  def resume_rtmp(pipeline, params) when is_pid(pipeline) do
    GenServer.call(pipeline, {:resume_rtmp, params})
  end

  @impl true
  def handle_init(context, %{app: stream_key, stream_key: ""} = state) do
    handle_init(context, %{state | stream_key: stream_key})
  end

  def handle_init(_context, %{app: @app, stream_key: stream_key, client_ref: client_ref}) do
    if user = Algora.Accounts.get_user_by(stream_key: stream_key) do
      video = Library.init_livestream!()
      {:ok, _} = Registry.register(Algora.Pipeline.Registry, stream_key, {:pipeline, video.uuid})

      dir = Path.join(Admin.tmp_dir(), video.uuid)
      :rpc.multicall(LLController, :start, [video.uuid, dir])

      {:ok, video} =
        Algora.Library.reconcile_livestream(
          %Algora.Library.Video{id: video.id},
          stream_key
        )

      destinations = Algora.Accounts.list_active_destinations(video.user_id)

      for {destination, i} <- Enum.with_index(destinations) do
        url =
          URI.new!(destination.rtmp_url)
          |> URI.append_path("/" <> destination.stream_key)
          |> URI.to_string()

        send(self(), {:forward_rtmp, url, String.to_atom("rtmp_sink_#{i}")})
      end

      if url = Algora.Accounts.get_restream_ws_url(user) do
        Task.Supervisor.start_child(
          Algora.TaskSupervisor,
          fn -> Algora.Restream.Websocket.start_link(%{url: url, user: user, video: video}) end,
          restart: :transient
        )
      end

      youtube_handle =
        case user.id do
          307 -> "@heyandras"
          9 -> "@dragonroyale"
          _ -> nil
        end

      if youtube_handle do
        DynamicSupervisor.start_child(
          Algora.Youtube.Chat.Supervisor,
          {Algora.Youtube.Chat.Fetcher, %{video: video, youtube_handle: youtube_handle}}
        )
      end

      structure = [
        #
        child({:src, 0}, %Algora.Pipeline.SourceBin{
          client_ref: client_ref,
        })
      ]

      send(self(), :setup_output)

      spec = {structure, group: :rtmp_input, crash_group_mode: :temporary}

      {
        [spec: spec],
        %__MODULE__{
          video: video,
          user: user,
          dir: dir,
          stream_key: stream_key,
        }
      }
    else
      {[reply: {:error, "invalid stream key"}, terminate: :normal], %{stream_key: stream_key}}
    end
  end

  def handle_init(_context, %{stream_key: stream_key}) do
    {[reply: {:error, "invalid app"}, terminate: :normal], %{stream_key: stream_key}}
  end

  def handle_child_notification({:track_playable, :video}, _element, _ctx, state) do
    {:ok, _ref} = :timer.send_after(@segment_duration_seconds * 1000, self(), :go_live)
    {[], state}
  end

  @impl true
  def handle_child_notification(:stream_interrupted, _element, _ctx, state) do
    state = terminate_later(state)
    {[], state}
  end

  def handle_child_notification(_message, _element, _ctx, state) do
    {[], state}
  end


  @impl true
  def handle_call(:get_video_id, _ctx, state) do
    {[{:reply, state.video.id}], state}
  end

  def handle_call({:resume_rtmp, %{ client_ref: client_ref }}, _ctx, state) do
    state = cancel_terminate(state)
    reconnect = state.reconnect + 1

    structure = [
      #
      child({:src, reconnect}, %Algora.Pipeline.SourceBin{
        client_ref: client_ref,
      }),

      #
      get_child({:src, reconnect})
      |> via_out(:video)
      |> child(%Membrane.H264.Parser{
        output_stream_structure: :annexb
      })
      |> child(Membrane.H264.FFmpeg.Decoder)
      |> child(Membrane.H264.FFmpeg.Encoder)
      |> get_child(:funnel_video),

      #
      get_child({:src, reconnect})
      |> via_out(:audio)
      |> get_child(:funnel_audio)
    ]

    {
      [
        spec: {structure, group: :rtmp_input, crash_group_mode: :temporary},
        reply: :ok
      ],
      %{state | reconnect: reconnect }
    }
  end


  @impl true
  def handle_info(:setup_output, _ctx, %{video: video, dir: dir, reconnect: reconnect} = state) do
    structure = [
      #
      get_child({:src, reconnect})
      |> via_out(:video)
      |> child(%Membrane.H264.Parser{
        output_stream_structure: :annexb
      })
      |> child(Membrane.H264.FFmpeg.Decoder)
      |> child(Membrane.H264.FFmpeg.Encoder)
      |> child(:funnel_video, %Algora.Pipeline.Funnel{ end_of_stream: :notify })
      |> child(:tee_video, Membrane.Tee.Parallel),

      #
      get_child({:src, reconnect})
      |> via_out(:audio)
      |> child(:funnel_audio, %Algora.Pipeline.Funnel{ end_of_stream: :notify })
      |> child(:tee_audio, Membrane.Tee.Parallel),

      #
      child(:sink, %Algora.Pipeline.SinkBin{
        video_uuid: video.uuid,
        hls_mode: :muxed_av,
        mode: :live,
        manifest_module: Algora.Pipeline.HLS,
        target_window_duration: :infinity,
        persist?: false,
        storage: %Algora.Pipeline.Storage{video: video, directory: dir}
      }),

      #
      get_child(:tee_audio)
      |> via_in(Pad.ref(:input, :audio),
        options: [
          encoding: :AAC,
          segment_duration: @segment_duration,
          partial_segment_duration: @partial_segment_duration
        ]
      )
      |> get_child(:sink),

      #
      get_child(:tee_video)
      |> via_in(Pad.ref(:input, :video),
        options: [
          encoding: :H264,
          segment_duration: @segment_duration,
          partial_segment_duration: @partial_segment_duration
        ]
      )
      |> get_child(:sink)
    ]

    spec = {structure, group: :hls_output}
    {[spec: spec], state}

  end

  def handle_info(:stream_interupted, _ctx, state) do
    {[], state}
  end

  def handle_info({:forward_rtmp, url, ref}, _ctx, state) do
    spec = [
      #
      child(ref, %Membrane.RTMP.Sink{rtmp_url: url}),

      #
      get_child(:tee_audio)
      |> via_in(Pad.ref(:audio, 0), toilet_capacity: 10_000)
      |> get_child(ref),

      #
      get_child(:tee_video)
      |> via_in(Pad.ref(:video, 0), toilet_capacity: 10_000)
      |> get_child(ref)
    ]

    {[spec: spec], state}
  end

  def handle_info(:multicast_algora, _ctx, state) do
    user = Algora.Accounts.get_user_by!(handle: "algora")
    destinations = Algora.Accounts.list_active_destinations(user.id)

    for destination <- destinations do
      url =
        URI.new!(destination.rtmp_url)
        |> URI.append_path("/" <> destination.stream_key)
        |> URI.to_string()

      send(self(), {:forward_rtmp, url, String.to_atom("rtmp_sink_#{destination.id}")})
    end

    if url = Algora.Accounts.get_restream_ws_url(user) do
      Task.Supervisor.start_child(
        Algora.TaskSupervisor,
        fn ->
          Algora.Restream.Websocket.start_link(%{
            url: url,
            user: user,
            video: state.video
          })
        end,
        restart: :transient
      )
    end

    {[], state}
  end

  def handle_info(:go_live, _ctx, state) do
    Algora.Library.toggle_streamer_live(state.video, true)
    {[], state}
  end

  def handle_info(:terminate, _ctx, state) do
    Algora.Library.toggle_streamer_live(state.video, false)
    {[terminate: :normal], state}
  end


  defp terminate_later(%{terminate_timer: nil} = state) do
    {:ok, timer} = :timer.send_after(@terminate_after, self(), :terminate)
    %{ state | terminate_timer: timer }
  end

  defp terminate_later(state) do
    state |> cancel_terminate() |> terminate_later()
  end

  defp cancel_terminate(%{terminate_timer: timer} = state) do
    :timer.cancel(timer)
    %{ state | terminate_timer: nil }
  end
end
