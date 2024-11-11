defmodule Algora.Pipeline do
  use Membrane.Pipeline
  require Membrane.Logger

  alias Membrane.Time
  alias Membrane.RTMP.Messages

  alias Algora.{Admin, Library}
  alias Algora.Pipeline.HLS.LLController

  @segment_duration_seconds 6
  @segment_duration Time.seconds(@segment_duration_seconds)
  @partial_segment_duration_milliseconds 1000
  @partial_segment_duration Time.milliseconds(@partial_segment_duration_milliseconds)
  @app "live"
  @terminate_after String.to_integer(Algora.config([:resume_rtmp_timeout])) * 1000
  @frame_devisor 1

  defstruct client_ref: nil,
            stream_key: nil,
            user: nil,
            video: nil,
            dir: nil,
            reconnect: 0,
            terminate_timer: nil,
            data_frame: nil,
            playing: false,
            finalized: false,
            forwarding: []

  def segment_duration(), do: @segment_duration_seconds

  def partial_segment_duration(), do: @partial_segment_duration_milliseconds

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

      :ok = :syn.register(:pipelines, stream_key, self(), video_uuid: video.uuid)
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

      setup_forwarding!(state)
      setup_extras!(state)

      spec = [
        #
        child({:src, reconnect}, %Algora.Pipeline.SourceBin{
          client_ref: client_ref
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
        })
      ]

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

  def handle_child_notification(:end_of_stream, :funnel_video, _ctx, %{finalized: true} = state) do
    {[], state}
  end

  def handle_child_notification(:end_of_stream, :funnel_video, _ctx, state) do
    state = terminate_later(state)
    # unlink next tick
    send(self(), :unlink_all)
    {[], state}
  end

  def handle_child_notification(:finalized, _element, _ctx, state) do
    Membrane.Logger.info("Finalized manifests for video #{inspect(state.video.uuid)}")
    {[terminate: :normal], state}
  end

  def handle_child_notification(message, element, _ctx, state) do
    Membrane.Logger.debug(
      "Unhandled child notification #{inspect(message)} from element #{inspect(element)}"
    )

    {[], state}
  end

  @impl true
  def handle_call(:get_video_id, _ctx, state) do
    {[{:reply, state.video.id}], state}
  end

  def handle_call({:resume_rtmp, %{client_ref: client_ref}}, _ctx, state) do
    state = cancel_terminate(state)
    reconnect = state.reconnect + 1

    Membrane.Logger.info("Attempting reconnection for video #{state.video.uuid}")

    structure = [
      #
      child({:src, reconnect}, %Algora.Pipeline.SourceBin{
        client_ref: client_ref
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
      |> get_child(:funnel_audio)
    ]

    send(self(), :link_tracks)
    setup_forwarding!(state)

    {
      [
        spec: {structure, group: :rtmp_input, crash_group_mode: :temporary},
        reply: :ok
      ],
      %{state | reconnect: reconnect}
    }
  end

  def handle_info(:link_tracks, _ctx, %{reconnect: reconnect} = state) do
    supports_h265 = Algora.config([:supports_h265])
    include_master = Algora.config([:transcode_include_master])

    structure =
      if transcode = transcode_formats(state.data_frame) do
        master_video_track(include_master) ++
          Enum.flat_map(transcode, fn opts ->
            transcode_track_h264(reconnect, opts) ++
              transcode_track_h265(reconnect, opts, supports_h265)
          end)
      else
        master_video_track(true)
      end

    structure =
      master_audio_track() ++ structure

    spec = {structure, group: :hls_adaptive}
    {[spec: spec], state}
  end

  def handle_info(:unlink_all, _ctx, %{reconnect: reconnect} = state) do
    actions =
      [
        remove_link: {:funnel_video, Pad.ref(:input, reconnect)},
        remove_link: {:funnel_audio, Pad.ref(:input, reconnect)},
        remove_link: {:sink, Pad.ref(:input, "audio_master")},
        remove_children: state.forwarding
      ]

      actions =
         if transcode_formats = transcode_formats(state.data_frame) do
           actions ++ Enum.flat_map(transcode_formats, fn %{track_name: track_name} ->
             [
               {:remove_link, {:sink, Pad.ref(:input, "#{track_name}")}},
               if Algora.config([:supports_h265]) do
                 {:remove_link, {:sink, Pad.ref(:input, "#{track_name}_h265")}}
               end
             ]
           end)
         else
           actions
         end

      actions =
         if is_nil(Algora.config([:transcode])) or Algora.config([:transcode_include_master]) do
           actions ++ [{:remove_link, {:sink, Pad.ref(:input, "video_master")}}]
         else
           actions
         end

    {Enum.filter(actions, & &1), %{state | forwarding: []}}
  end

  def handle_info({:forward_rtmp, url, ref}, _ctx, state) do
    ref = {ref, state.reconnect}
    if Enum.member?(state.forwarding, ref) do
      {[], state}
    else
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

      {[spec: spec], %{state | forwarding: [ref | state.forwarding]}}
    end
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

  def handle_info(
        {:metadata_message, %Messages.SetDataFrame{} = message},
        _ctx,
        %{data_frame: nil} = state
      ) do
    send(self(), :link_tracks)
    {[], %{state | data_frame: message}}
  end

  def handle_info({:metadata_message, _message}, _ctx, state) do
    {[], state}
  end

  def handle_info(%Messages.Anonymous{name: "FCUnpublish"}, _ctx, state) do
    unless Algora.config([:resume_rtmp_on_unpublish]), do: send(self(), :terminate)
    {[], state}
  end

  def handle_info(%Messages.DeleteStream{}, _ctx, state) do
    unless Algora.config([:resume_rtmp_on_unpublish]), do: send(self(), :terminate)
    {[], state}
  end

  def handle_info(:terminate, _ctx, state) do
    Membrane.Logger.info("Terminating pipeline for video #{state.video.uuid}")
    Algora.Library.toggle_streamer_live(state.video, false)
    {[terminate: :normal, notify_child: {:sink, :finalize}], %{state | finalized: true}}
  end

  def handle_info(message, _ctx, state) do
    Membrane.Logger.info("Unhandled notification #{inspect(message)}")
    {[], state}
  end

  def master_video_track(false), do: []
  def master_video_track(true) do
    [
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
      |> get_child(:sink)
    ]
  end

  defp master_audio_track() do
    [
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
  end

  def transcode_track_h264(reconnect, %{track_name: track_name} = opts) do
    [
      #
      get_child(:tee_video)
      |> do_transcode_track_h264(opts, Algora.config([:transcode_backend]))
      |> child({:tee_video_transcoder, "#{track_name}-#{reconnect}"}, Membrane.Tee.Parallel),

      #
      get_child({:tee_video_transcoder, "#{track_name}-#{reconnect}"})
      |> child({:video_reconnect, "#{track_name}-#{reconnect}"}, Membrane.Tee.Parallel)
      |> via_in(Pad.ref(:input, "#{track_name}"),
        options: [
          track_name: "#{track_name}",
          encoding: :H264,
          segment_duration: @segment_duration,
          partial_segment_duration: @partial_segment_duration
        ]
      )
      |> get_child(:sink)
    ]
  end

  def transcode_track_h265(reconnect, %{track_name: track_name}, true) do
    [
      #
      get_child({:tee_video_transcoder, "#{track_name}-#{reconnect}"})
      |> child(%Membrane.H264.Parser{
        output_stream_structure: :annexb,
        generate_best_effort_timestamps: %{framerate: {-1, @frame_devisor}}
      })
      |> child(Membrane.H264.FFmpeg.Decoder)
      |> child(%Membrane.H265.FFmpeg.Encoder{
        preset: :veryfast,
        tune: :zerolatency,
        crf: 40
      })
      |> child({:video_reconnect, "#{track_name}-#{reconnect}_h265"}, Membrane.Tee.Parallel)
      |> via_in(Pad.ref(:input, "#{track_name}_h265"),
        options: [
          track_name: "#{track_name}_h265",
          encoding: :H265,
          segment_duration: @segment_duration,
          partial_segment_duration: @partial_segment_duration
        ]
      )
      |> get_child(:sink)
    ]
  end

  def transcode_track_h265(_reconnect, _opts, _enabled), do: []

  defp do_transcode_track_h264(
         from_child,
         %{framerate: framerate, height: height, width: width, bitrate: bitrate},
         nil
       ) do
    from_child
    |> child(%Membrane.H264.Parser{
      output_stream_structure: :annexb,
      generate_best_effort_timestamps: %{framerate: {-1, @frame_devisor}}
    })
    |> child(Membrane.H264.FFmpeg.Decoder)
    |> child(%Membrane.FramerateConverter{framerate: {trunc(framerate), @frame_devisor}})
    |> child(%Membrane.FFmpeg.SWScale.Scaler{
      output_height: height,
      output_width: width
    })
    |> child(%Membrane.H264.FFmpeg.Encoder{
      ffmpeg_params: %{"b" => "#{bitrate}"},
      preset: :veryfast,
      tune: :zerolatency,
      crf: 26
    })
  end

  defp do_transcode_track_h264(from_child, opts, backend) do
    from_child
    |> child(%Membrane.H264.Parser{
      output_stream_structure: :annexb,
      generate_best_effort_timestamps: %{framerate: {opts[:framerate], @frame_devisor}}
    })
    |> child(%Membrane.ABRTranscoder{
      backend: backend
      # min_inter_frame_delay: opts[:min_inter_frame_delay]
    })
    |> via_out(:output,
      options: [
        width: opts[:width],
        height: opts[:height],
        framerate: :full,
        bitrate: opts[:bitrate]
      ]
    )
  end

  defp setup_forwarding!(%{video: video} = state) do
    destinations = Algora.Accounts.list_active_destinations(video.user_id)

    for destination <- destinations do
      url =
        URI.new!(destination.rtmp_url)
        |> URI.append_path("/" <> destination.stream_key)
        |> URI.to_string()

      send(self(), {:forward_rtmp, url, String.to_atom("rtmp_sink_#{destination.id}")})
    end
  end

  defp setup_extras!(%{video: video, user: user} = state) do
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
  end

  defp terminate_later(state), do: terminate_later(state, @terminate_after)

  defp terminate_later(%{terminate_timer: nil} = state, time) do
    time = if Algora.config([:resume_rtmp]), do: time, else: 0
    {:ok, timer} = :timer.send_after(time, self(), :terminate)
    %{state | terminate_timer: timer}
  end

  defp terminate_later(state, time) do
    state |> cancel_terminate() |> terminate_later(time)
  end

  defp cancel_terminate(%{terminate_timer: timer} = state) do
    :timer.cancel(timer)
    %{state | terminate_timer: nil}
  end

  defp normalize_scale(scale) when is_float(scale), do: scale |> trunc() |> normalize_scale()

  defp normalize_scale(scale) when is_integer(scale) and scale > 0 do
    if rem(scale, 2) == 1, do: scale - 1, else: scale
  end

  defp transcode_formats(nil), do: nil

  defp transcode_formats(%{
         height: source_height,
         width: source_width,
         framerate: source_framerate
       }) do
    if transcode_config = get_transcode_config() do
      transcode_config
      |> Enum.filter(fn {target_height, framerate, _bitrate} ->
        target_height <= source_height and framerate <= source_framerate
      end)
      |> Enum.map(fn {target_height, target_framerate, bitrate} ->
        height = normalize_scale(target_height)
        width = normalize_scale(source_width / (source_height / target_height))
        framerate = trunc(target_framerate)
        track_name = "video_#{width}x#{height}p#{framerate}"

        %{
          height: height,
          width: width,
          framerate: framerate,
          track_name: track_name,
          bitrate: bitrate
        }
      end)
    end
  end

  defp get_transcode_config() do
    if transcode_slug = Algora.config([:transcode]) do
      transcode_slug
      |> String.split("|")
      |> Enum.map(&String.split(&1, "p"))
      |> Enum.map(fn [height, framerate_bitrate] ->
        [framerate, bitrate] = String.split(framerate_bitrate, "@")

        {
          String.to_integer(height),
          String.to_integer(framerate),
          String.to_integer(bitrate)
        }
      end)
    end
  end
end
