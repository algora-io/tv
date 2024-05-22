defmodule AlgoraWeb.OAuthController do
  use AlgoraWeb, :controller
  require Logger

  def new(conn, %{"provider" => "restream"} = params) do
    state = Algora.Util.random_string()

    # TODO: ensure user is logged in

    conn
    |> put_session(:user_return_to, params["return_to"])
    |> put_session(:restream_state, state)
    |> redirect(external: Algora.Restream.authorize_url(state))
  end
end
