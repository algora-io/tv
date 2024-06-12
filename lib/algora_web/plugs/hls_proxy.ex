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
         %{"_HLS_msn" => msn, "_HLS_part" => part, "filename" => filename} = params
       ) do
    msn = String.to_integer(msn)
    part = String.to_integer(part)

    [_bucket, uuid, _file] = conn.path_info

    pid =
      Admin.pipelines()
      |> Enum.find(fn pid -> GenServer.call(pid, :get_video_uuid) == uuid end)

    dbg({:pending, params})

    if pid do
      Task.async(fn ->
        wait_until(fn ->
          %{hls_msn: hls_msn, hls_part: hls_part} = GenServer.call(pid, :get_hls_params)
          dbg({{hls_msn, hls_part}, {msn, part}})

          # ready = hls_msn > msn or (hls_msn == msn and hls_part >= part)
          ready = {hls_msn, hls_part} >= {msn, part}
          dbg(ready)

          ready
        end)
      end)
      |> Task.await(:infinity)
    else
      dbg({:failure, params})
    end

    dbg({:success, params})

    # params
    # |> Map.delete("_HLS_msn")
    # |> Map.delete("_HLS_part")
    # |> then(&handle_manifest_req(conn, opts, &1))

    [bucket, uuid, _file] = conn.path_info
    Plug.forward(conn, [bucket, uuid, filename], ReverseProxyPlug, opts)
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
