defmodule AlgoraWeb.Router do
  use AlgoraWeb, :router

  import AlgoraWeb.UserAuth,
    only: [redirect_if_user_is_authenticated: 2, fetch_current_user: 2]

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :fetch_current_user
    plug :put_root_layout, {AlgoraWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", AlgoraWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    get "/oauth/callbacks/:provider", OAuthCallbackController, :new
  end

  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser
      live_dashboard "/dashboard", metrics: AlgoraWeb.Telemetry
    end
  end

  if Mix.env() == :dev do
    scope "/dev" do
      pipe_through :browser

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  scope "/", AlgoraWeb do
    pipe_through :browser

    delete "/auth/logout", OAuthCallbackController, :sign_out

    live_session :authenticated,
      on_mount: [{AlgoraWeb.UserAuth, :ensure_authenticated}, AlgoraWeb.Nav] do
      live "/channel/settings", SettingsLive, :edit
      live "/:channel_handle/stream", ChannelLive, :stream

      live "/videos/:video_id/subtitles", SubtitleLive.Index, :index
      live "/videos/:video_id/subtitles/new", SubtitleLive.Index, :new
      live "/videos/:video_id/subtitles/:id", SubtitleLive.Show, :show
      live "/videos/:video_id/subtitles/:id/edit", SubtitleLive.Index, :edit
      live "/videos/:video_id/subtitles/:id/show/edit", SubtitleLive.Show, :edit
    end

    live_session :default, on_mount: [{AlgoraWeb.UserAuth, :current_user}, AlgoraWeb.Nav] do
      live "/", HomeLive, :show
      live "/auth/login", SignInLive, :index
      live "/:channel_handle", ChannelLive, :show
      live "/:channel_handle/:video_id", VideoLive, :show
    end
  end
end
