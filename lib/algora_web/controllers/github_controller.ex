defmodule AlgoraWeb.GithubController do
  use AlgoraWeb, :controller

  alias Algora.{Accounts, Library}

  def get_thumbnail(conn, %{"user_id" => user_id}) do
    with {:ok, user} <- get_user(user_id),
         {:ok, video} <- get_latest_video(user) do
      redirect(conn, external: get_thumbnail_url(video))
    else
      {:error, :video_not_found} -> redirect(conn, to: ~p"/images/og/default.png")
      _ -> send_resp(conn, 404, "Not found")
    end
  end

  def get_channel(conn, %{"user_id" => user_id}) do
    case get_user(user_id) do
      {:ok, user} ->
        redirect(conn, to: ~p"/#{user.handle}")

      _ ->
        send_resp(conn, 404, "Not found")
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

  defp get_thumbnail_url(video) do
    case video.thumbnail_url do
      nil -> ~p"/images/og/default.png"
      url -> url
    end
  end
end
