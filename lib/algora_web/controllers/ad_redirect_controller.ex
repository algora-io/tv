defmodule AlgoraWeb.AdRedirectController do
  use AlgoraWeb, :controller
  alias Algora.Ads

  def go(conn, %{"slug" => slug}) do
    ad = Ads.get_ad_by_slug!(slug)

    ## TODO: log errors
    Ads.track_visit(%{ad_id: ad.id})

    conn
    |> put_status(:found)
    |> redirect(external: ad.website_url)
  end
end
