defmodule AlgoraWeb.AdRedirectController do
  use AlgoraWeb, :controller
  alias Algora.Ads

  def go(conn, %{"ad_id" => ad_id}) do
    case Integer.parse(ad_id) do
      {id, ""} ->
        ad = Ads.get_ad!(id)

        ## TODO: log errors
        Ads.track_visit(%{ad_id: id})

        conn
        |> put_status(:found)
        |> redirect(external: ad.website_url)

      _ ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: "Invalid ad_id format"})
    end
  end
end
