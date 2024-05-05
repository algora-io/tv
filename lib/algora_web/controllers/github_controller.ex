defmodule AlgoraWeb.GithubController do
  use AlgoraWeb, :controller

  alias Algora.{Accounts, Library}

  def get_thumbnail(conn, %{"user_id" => user_id}) do
    with {:ok, user} <- get_user(user_id),
         {:ok, video} <- get_latest_video(user) do
      redirect(conn, external: video.thumbnail_url)
    else
      {:error, :video_not_found} -> redirect(conn, to: ~p"/images/og/default.png")
      # TODO:
      _ -> redirect(conn, to: "~p/status/404")
    end
  end

  def get_channel(conn, %{"user_id" => user_id}) do
    case get_user(user_id) do
      {:ok, user} ->
        redirect(conn, to: ~p"/#{user.handle}")

      _ ->
        # TODO
        redirect(conn, to: "~p/status/404")
    end
  end

  defp get_user(id) do
    case Accounts.get_user_by_provider_id(:github, id) do
      nil -> {:error, :user_not_found}
      user -> {:ok, user}
    end
  end

  defp get_latest_video(user) do
    case Library.get_latest_video(user) do
      nil -> {:error, :video_not_found}
      user -> {:ok, user}
    end
  end
end
