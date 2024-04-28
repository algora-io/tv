defmodule AlgoraWeb.EmbedPopoutController do
  use AlgoraWeb, :controller

  alias Algora.{Accounts, Library}

  def get(conn, %{"channel_handle" => channel_handle}) do
    user = Accounts.get_user_by!(handle: channel_handle)

    case Library.get_latest_video(user) do
      nil ->
        redirect(conn, to: ~p"/#{user.handle}")

      video ->
        redirect(conn,
          external:
            "https://#{URI.parse(AlgoraWeb.Endpoint.url()).host}:444/#{channel_handle}/#{video.id}/embed"
        )
    end
  end

  def get_by_id(conn, %{"channel_handle" => channel_handle, "video_id" => video_id}) do
    redirect(conn,
      external:
        "https://#{URI.parse(AlgoraWeb.Endpoint.url()).host}:444/#{channel_handle}/#{video_id}/embed"
    )
  end
end
