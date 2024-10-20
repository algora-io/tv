defmodule AlgoraWeb.RedirectController do
  use AlgoraWeb, :controller

  import AlgoraWeb.UserAuth, only: [fetch_current_user: 2]

  plug :fetch_current_user

  def redirect_authenticated(conn, _) do
    if conn.assigns.current_user do
      AlgoraWeb.UserAuth.redirect_if_user_is_authenticated(conn, [])
    else
      redirect(conn, to: ~p"/auth/login")
    end
  end

  def redirect_tembo(conn, _params) do
    redirect(conn, to: "/algora/10745")
  end
end
