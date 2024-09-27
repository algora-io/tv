defmodule AlgoraWeb.OAuthLoginController do
  use AlgoraWeb, :controller
  require Logger
  import AlgoraWeb.UserAuth, only: [maybe_store_return_to: 1]

  def new(conn, %{"provider" => "restream"} = params) do
    if conn.assigns.current_user do
      state = Algora.Util.random_string()

      conn
      |> put_session(:user_return_to, params["return_to"])
      |> put_session(:restream_state, state)
      |> redirect(external: Algora.Restream.authorize_url(state))
    else
      conn 
      |> maybe_store_return_to()
      |> redirect(to: ~p"/auth/login")
    end
  end
end
