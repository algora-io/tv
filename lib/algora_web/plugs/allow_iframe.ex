defmodule AlgoraWeb.Plugs.AllowIframe do
  import Plug.Conn
  def init(_), do: %{}

  def call(conn, _opts) do
    put_resp_header(
      conn,
      "content-security-policy",
      "frame-ancestors 'self' *"
    )
  end
end
