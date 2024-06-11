defmodule AlgoraWeb.Plugs.HLSProxy do
  alias Algora.Admin

  defdelegate init(opts), to: ReverseProxyPlug

  def call(conn, opts) do
    [_bucket, _uuid, filename] = conn.path_info

    case filename do
      # _ <> ".m3u8" ->
      #   handle_partial_req(conn, opts, %{conn.params | filename: filename})

      _ ->
        Plug.forward(conn, conn.path_info, ReverseProxyPlug, opts)
    end
  end

  defp handle_hls_req(
         conn,
         %{
           "_HLS_skip" => _skip
         } = params
       ) do
    handle_hls_req(conn, params)
  end

  defp handle_partial_req(conn, opts, %{"_HLS_msn" => msn, "_HLS_part" => part} = params) do
    [_bucket, uuid, _file] = conn.path_info

    pid =
      Admin.pipelines()
      |> Enum.find(fn pid -> GenServer.call(pid, :get_video_uuid) == uuid end)

    dbg({:pending, params})

    if pid do
      Task.async(fn ->
        wait_until(fn ->
          %{hls_msn: hls_msn, hls_part: hls_part} = GenServer.call(pid, :get_hls_params)
          hls_msn > msn or (hls_msn == msn and hls_part >= part)
        end)
      end)
      |> Task.await(:infinity)
    else
      dbg({:failure, params})
    end

    dbg({:success, params})

    Plug.forward(conn, conn.path_info, ReverseProxyPlug, opts)
  end

  defp wait_until(cb) do
    unless cb.() do
      :timer.sleep(10)
      wait_until(cb)
    end
  end
end
