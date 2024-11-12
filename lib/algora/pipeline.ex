defmodule Algora.Pipeline do
  use Membrane.Pipeline
  require Membrane.Logger

  alias Membrane.Time

  alias Algora.{Admin, Library}
  alias Algora.Pipeline.HLS.LLController

  @segment_duration_seconds 6
  @segment_duration Time.seconds(@segment_duration_seconds)
  @partial_segment_duration_milliseconds 200
  @partial_segment_duration Time.milliseconds(@partial_segment_duration_milliseconds)
  @app "live"
  @terminate_after 60_000 * 60
  @reconnect_inactivity_timeout 12_000
  @frame_devisor 1

  defstruct [
    client_ref: nil,
    stream_key: nil,
    user: nil,
    video: nil,
    dir: nil,
    reconnect: 0,
    terminate_timer: nil,
    waiting_activity: true,
    data_frame: nil,
    playing: false,
  ]

  def segment_duration(), do: @segment_duration_seconds

  def partial_segment_duration(), do: @partial_segment_duration_milliseconds

  def handle_new_client(client_ref, app, stream_key) do
    Membrane.Logger.info("Handling new client for pipeline #{app}")
    params = %{
      client_ref: client_ref,
      app: app,
      stream_key: stream_key,
      video_uuid: nil
    }

    {:ok, pid} = with true <- Algora.config([:resume_rtmp]),
       {pid, metadata} when is_pid(pid) <- :syn.lookup(:pipelines, stream_key) do
         Algora.Pipeline.resume_rtmp(pid, %{ params | video_uuid: metadata[:video_uuid] })
         {:ok, pid}
     else
      _ ->
        {:ok, _sup, pid} =
          Membrane.Pipeline.start_link(Algora.Pipeline, params)
        {:ok, pid}
    end

    Algora.Pipeline.ClientHandler
  end

  def resume_rtmp(pipeline, params) when is_pid(pipeline) do
    Membrane.Logger.info("Resuming pipeline #{inspect(params)}")
    GenServer.call(pipeline, {:resume_rtmp, params})
  end

  @impl true
  def handle_init(context, %{app: stream_key, stream_key: ""} = params) do
    handle_init(context, %{params | stream_key: stream_key})
  end

  def handle_init(_context, %{app: @app, stream_key: stream_key, client_ref: client_ref}) do
    Membrane.Logger.info("Starting pipeline #{@app}")
    if user = Algora.Accounts.get_user_by(stream_key: stream_key) do
      video = Library.init_livestream!()
      dir = Path.join(Admin.tmp_dir(), video.uuid)

      :ok = :syn.register(:pipelines, stream_key, self(), [video_uuid: video.uuid])
      :rpc.multicall(LLController, :start, [video.uuid, dir])

      {:ok, video} =
        Algora.Library.reconcile_livestream(
          %Algora.Library.Video{id: video.id},
          stream_key
        )

      reconnect = 0
      state = %__MODULE__{
        video: video,
        user: user,
        dir: dir,
        stream_key: stream_key,
        reconnect: reconnect
      }

      {:ok, state} = setup_extras!(state)

      spec = [
        #
        child({:src, reconnect}, %Algora.Pipeline.SourceBin{
          client_ref: client_ref,
        }),

        get_child({:src, reconnect})
        |> via_out(:video)
        |> child({:video_reconnect, reconnect}, Membrane.Tee.Parallel)
        |> via_in(Pad.ref(:input, reconnect))
        |> child(:funnel_video, %Algora.Pipeline.Funnel{end_of_stream: :notify})
        |> child(:tee_video, Membrane.Tee.Parallel),

        #
        get_child({:src, reconnect})
        |> via_out(:audio)
        |> child({:audio_reconnect, reconnect}, Membrane.Tee.Parallel)
        |> via_in(Pad.ref(:input, reconnect))
        |> child(:funnel_audio, %Algora.Pipeline.Funnel{end_of_stream: :notify})
        |> child(:tee_audio, Membrane.Tee.Parallel),

        #
        child(:sink, %Algora.Pipeline.SinkBin{
          video_uuid: video.uuid,
          hls_mode: :separate_av,
          mode: :live,
          manifest_module: Algora.Pipeline.HLS,
          target_window_duration: :infinity,
          persist?: true,
          storage: %Algora.Pipeline.Storage{video: video, directory: dir}
        }),
      ]

      send(self(), :link_tracks)

      {[spec: spec], state}
    else
      Membrane.Logger.debug("Invalid stream_key")
      {[reply: {:error, "invalid stream key"}, terminate: :normal], %{stream_key: stream_key}}
    end
  end

  def handle_init(_context, %{stream_key: stream_key}) do
    {[reply: {:error, "invalid app"}, terminate: :normal], %{stream_key: stream_key}}
  end

  @impl true
  def handle_child_notification({:track_playable, :video}, _element, _ctx, state) do
    {[], state}
  end

  def handle_child_notification({:track_activity, track}, _element, _ctx,  %{playing: false, waiting_activity: true} = state) do
    Membrane.Logger.debug("Got activity on track #{track} for video #{state.video.uuid}")
    Algora.Library.toggle_streamer_live(state.video, true)
    {[], %{ state | waiting_activity: false, playing: true }}
  end

  def handle_child_notification({:track_activity, track}, _element, _ctx,  %{waiting_activity: true} = state) do
    Membrane.Logger.debug("Got activity on track #{track} for video #{state.video.uuid}")
    {[], %{ state | waiting_activity: false }}
  end

  def handle_child_notification({:track_activity, track}, _element, _ctx, state) do
    {[], state}
  end

  def handle_child_notification(:end_of_stream, :funnel_video, _ctx, state) do
    state = terminate_later(state)
    # unlink next tick
    send(self(), :unlink_all)
    {[], state}
  end

  def handle_child_notification(message, _element, _ctx, state) do
    Membrane.Logger.info("Unhandled child notification #{inspect(message)}")
    {[], state}
  end

  @impl true
  def handle_call(:get_video_id, _ctx, state) do
    {[{:reply, state.video.id}], state}
  end

  def handle_call({:resume_rtmp, %{ client_ref: client_ref }}, _ctx, state) do
    state = cancel_terminate(state)
    reconnect = state.reconnect + 1

    Membrane.Logger.debug("Attempting reconnection for video #{state.video.uuid}")

    structure = [
      #
      child({:src, reconnect}, %Algora.Pipeline.SourceBin{
        client_ref: client_ref,
      }),

      #
      get_child({:src, reconnect})
      |> via_out(:video)
      |> child({:video_reconnect, reconnect}, Membrane.Tee.Parallel)
      |> via_in(Pad.ref(:input, reconnect))
      |> get_child(:funnel_video),

      #
      get_child({:src, reconnect})
      |> via_out(:audio)
      |> child({:audio_reconnect, reconnect}, Membrane.Tee.Parallel)
      |> via_in(Pad.ref(:input, reconnect))
      |> get_child(:funnel_audio),
    ]

    send(self(), :link_tracks)

    :timer.send_after(@reconnect_inactivity_timeout, :reconnect_inactivity)

    {
      [
        spec: {structure, group: :rtmp_input, crash_group_mode: :temporary},
        reply: :ok,
      ],
      %{state | reconnect: reconnect, waiting_activity: true }
    }
  end

  def handle_info(:link_tracks, _ctx, %{reconnect: reconnect} = state) do
    spec = [
      #
      get_child(:tee_video)
      |> via_in(Pad.ref(:input, "video_master"),
        options: [
          track_name: "video_master",
          encoding: :H264,
          segment_duration: @segment_duration,
          partial_segment_duration: @partial_segment_duration
        ]
      )
      |> get_child(:sink),

      #
      get_child(:tee_audio)
      |> via_in(Pad.ref(:input, "audio_master"),
        options: [
          track_name: "audio_master",
          encoding: :AAC,
          segment_duration: @segment_duration,
          partial_segment_duration: @partial_segment_duration
        ]
      )
      |> get_child(:sink)
    ]

    {[spec: spec], state}
  end

  def handle_info(:unlink_all, _ctx, %{reconnect: reconnect} = state) do
    actions = [
      remove_link: {:funnel_video, Pad.ref(:input, reconnect)},
      remove_link: {:funnel_audio, Pad.ref(:input, reconnect)},
      remove_link: {:sink, Pad.ref(:input, "audio_master")},
      remove_link: {:sink, Pad.ref(:input, "video_master")},
    ]

    {actions, state}
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

  def handle_info(:reconnect_inactivity, _ctx, %{ waiting_activity: true } = state) do
    Membrane.Logger.error("Tried to reconnect but failed #{inspect(state)}")
    send(self(), :terminate)
    {[], state}
  end

  def handle_info(:reconnect_inactivity, _ctx, state), do: {[], state}


  def handle_info(:terminate, _ctx, state) do
    Algora.Library.toggle_streamer_live(state.video, false)
    Membrane.Pipeline.terminate(self(), asynchronous?: true)
    {[notify_child: {:sink, :finalize}], state}
  end

  def handle_info(message, _ctx, state) do
    Membrane.Logger.info("Unhandled notification #{inspect(message)}")
    {[], state}
  end

  defp setup_extras!(%{ video: video, user: user } = state) do
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

    {:ok, state}
  end

  defp terminate_later(%{terminate_timer: nil} = state) do
    time = if Algora.config([:resume_rtmp]), do: @terminate_after, else: 0
    {:ok, timer} = :timer.send_after(time, self(), time)
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
