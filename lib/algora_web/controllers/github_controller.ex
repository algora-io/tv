defmodule AlgoraWeb.GithubController do
  use AlgoraWeb, :controller

  alias Algora.{Accounts, Library}

  def get_thumbnail(conn, %{"user_id" => user_id}) do
    case Accounts.get_user_by_provider_id(:github, user_id) do
      nil -> send_resp(conn, 404, "Not found")
      user -> redirect(conn, external: Library.get_og_image_url(user))
    end
  end

  def get_channel(conn, %{"user_id" => user_id}) do
    case Accounts.get_user_by_provider_id(:github, user_id) do
      nil -> send_resp(conn, 404, "Not found")
      user -> redirect(conn, to: ~p"/#{user.handle}")
    end
  end
end
