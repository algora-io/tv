defmodule Algora.Google do
  @moduledoc """
  This module contains Google-related functions.
  For now, it only contains the function to referesh the user token for the YouTube integration
  Perhaps, as time goes on, it'll contain more.
  """

  alias GoogleApi.YouTube.V3, as: YouTube
  alias Algora.Accounts
  alias Algora.Accounts.User

  def refresh_access_token(refresh_token) do
    body =
      URI.encode_query(%{
        client_id: client_id(),
        client_secret: client_secret(),
        refresh_token: refresh_token,
        grant_type: "refresh_token"
      })

    headers = [
      {"Content-Type", "application/x-www-form-urlencoded"}
    ]

    res = HTTPoison.post("https://oauth2.googleapis.com/token", body, headers)

    with {:ok, %HTTPoison.Response{status_code: 200, body: body}} <- res,
         %{"access_token" => token} = decoded_body <- Jason.decode!(body) do
      new_refresh_token = Map.get(decoded_body, "refresh_token", refresh_token)
      {:ok, %{token: token, refresh_token: new_refresh_token}}
    else
      {:error, %HTTPoison.Error{reason: reason}} -> {:error, reason}
      %{} = res -> {:error, {:bad_response, res}}
    end
  end

  def upload_video(user = %User{}, path, %{
        title: title,
        description: description,
        privacy_status: privacy_status
      }) do
    conn = Accounts.get_google_token(user) |> YouTube.Connection.new()

    YouTube.Api.Videos.youtube_videos_insert_simple(
      conn,
      ["snippet", "status"],
      "multipart",
      %YouTube.Model.Video{
        snippet: %YouTube.Model.VideoSnippet{
          title: title,
          description: description
        },
        status: %YouTube.Model.VideoStatus{
          privacyStatus: privacy_status
        }
      },
      path
    )
  end

  defp client_id,
    do: Application.fetch_env!(:ueberauth, Ueberauth.Strategy.Google.OAuth)[:client_id]

  defp client_secret,
    do: Application.fetch_env!(:ueberauth, Ueberauth.Strategy.Google.OAuth)[:client_secret]
end
