defmodule AlgoraWeb.Plugs.HLSProxy do
  alias Algora.Admin

  defdelegate init(opts), to: ReverseProxyPlug

  def call(conn, opts) do
    [_bucket, _uuid, filename] = conn.path_info

    if String.ends_with?(filename, ".m3u8") do
      conn.params
      |> Map.put("filename", filename)
      |> then(&handle_manifest_req(conn, opts, &1))
    else
      Plug.forward(conn, conn.path_info, ReverseProxyPlug, opts)
    end
  end

  defp handle_manifest_req(conn, opts, %{"_HLS_skip" => _skip} = params) do
    params
    |> Map.update!("filename", &String.replace_suffix(&1, ".m3u8", "_delta.m3u8"))
    |> Map.delete("_HLS_skip")
    |> then(&handle_manifest_req(conn, opts, &1))
  end

  defp handle_manifest_req(
         conn,
         opts,
         %{"_HLS_msn" => hls_msn, "_HLS_part" => hls_part} = params
       ) do
    hls_msn = String.to_integer(hls_msn)
    hls_part = String.to_integer(hls_part)

    [_bucket, uuid, _file] = conn.path_info

    pid =
      Admin.pipelines()
      |> Enum.find(fn pid -> GenServer.call(pid, :get_video_uuid) == uuid end)

    dbg({:pending, {hls_msn, hls_part}})

    if pid do
      Task.async(fn ->
        wait_until(fn ->
          %{segment_sn: segment_sn, partial_sn: partial_sn} =
            GenServer.call(pid, :get_sequence_numbers)

          ready = {segment_sn, partial_sn} >= {hls_msn, hls_part}

          if ready, do: dbg({:ready, {segment_sn, partial_sn}})

          ready
        end)
      end)
      |> Task.await(:infinity)
    else
      dbg({:failure, params})
    end

    params
    |> Map.delete("_HLS_msn")
    |> Map.delete("_HLS_part")
    |> then(&handle_manifest_req(conn, opts, &1))
  end

  defp handle_manifest_req(conn, opts, %{"filename" => filename}) do
    [bucket, uuid, _file] = conn.path_info
    Plug.forward(conn, [bucket, uuid, filename], ReverseProxyPlug, opts)
  end

  defp wait_until(cb) do
    unless cb.() do
      :timer.sleep(10)
      wait_until(cb)
    end
  end
end
