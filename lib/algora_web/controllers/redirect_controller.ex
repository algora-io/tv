defmodule AlgoraWeb.RedirectController do
  use AlgoraWeb, :controller

  import AlgoraWeb.UserAuth, only: [fetch_current_user: 2, maybe_store_return_to: 1]

  plug :fetch_current_user

  def redirect_authenticated(conn, _) do
    if conn.assigns.current_user do
      AlgoraWeb.UserAuth.redirect_if_user_is_authenticated(conn, [])
    else
      conn
      |> maybe_store_return_to()
      |> redirect(to: ~p"/auth/login")
    end
  end
end
