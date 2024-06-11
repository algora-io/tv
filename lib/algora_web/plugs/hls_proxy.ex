defmodule AlgoraWeb.Plugs.HLSProxy do
  defdelegate init(opts), to: ReverseProxyPlug

  def call(conn, opts) do
    case conn.params do
      %{"_HLS_msn" => msn, "_HLS_part" => part} ->
        handle_partial_req(conn, opts, %{
          "_HLS_msn" => String.to_integer(msn),
          "_HLS_part" => String.to_integer(part)
        })

      _ ->
        Plug.forward(conn, conn.path_info, ReverseProxyPlug, opts)
    end
  end

  defp handle_partial_req(conn, opts, %{"_HLS_msn" => _msn, "_HLS_part" => _part}) do
    Plug.forward(conn, conn.path_info, ReverseProxyPlug, opts)
  end
end
