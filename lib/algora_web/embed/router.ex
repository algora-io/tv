defmodule AlgoraWeb.Embed.Router do
  use AlgoraWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :put_root_layout, {AlgoraWeb.Layouts, :root_embed}
    plug :put_secure_browser_headers
  end

  pipeline :embed do
    plug AlgoraWeb.Plugs.AllowIframe
  end

  scope "/", AlgoraWeb do
    pipe_through [:browser, :embed]

    live_session :embed,
      layout: {AlgoraWeb.Layouts, :live_bare} do
      live "/:channel_handle/:video_id/embed", EmbedLive, :show
    end
  end
end
