defmodule AlgoraWeb.OAuthController do
  use AlgoraWeb, :controller
  require Logger

  def new(conn, %{"provider" => "restream"} = params) do
    if conn.assigns.current_user do
      state = Algora.Util.random_string()

      conn
      |> put_session(:user_return_to, params["return_to"])
      |> put_session(:restream_state, state)
      |> redirect(external: Algora.Restream.authorize_url(state))
    else
      conn |> redirect(to: ~p"/auth/login")
    end
  end
end
