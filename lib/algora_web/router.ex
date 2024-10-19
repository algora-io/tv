defmodule AlgoraWeb.Router do
  use AlgoraWeb, :router

  import AlgoraWeb.UserAuth, only: [fetch_current_user: 2]

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

  pipeline :embed do
    plug AlgoraWeb.Plugs.AllowIframe
  end

  pipeline :transform_docs do
    plug AlgoraWeb.Plugs.TransformDocs
  end

  scope "/", AlgoraWeb do
    pipe_through :browser

    get "/oauth/callbacks/:provider", OAuthCallbackController, :new
    get "/oauth/login/:provider", OAuthLoginController, :new
  end

  scope "/", AlgoraWeb do
    get "/hls/:video_uuid/:filename", HLSContentController, :index
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

  scope "/auth", AlgoraWeb do
    pipe_through :browser

    live_session :auth_login, on_mount: [{AlgoraWeb.UserAuth, :current_user}, AlgoraWeb.Nav] do
      live "/login", SignInLive, :index
    end

    get "/:provider", YoutubeAuthController, :request
    get "/:provider/callback", YoutubeAuthController, :callback
  end

  scope "/", AlgoraWeb do
    pipe_through [:browser, :embed]

    get "/:channel_handle/latest", VideoPopoutController, :get
    get "/:channel_handle/embed", EmbedPopoutController, :get
    get "/:channel_handle/:video_id/embed", EmbedPopoutController, :get_by_id

    live_session :ads,
      layout: {AlgoraWeb.Layouts, :live_bare},
      root_layout: {AlgoraWeb.Layouts, :root_embed},
      on_mount: [{AlgoraWeb.UserAuth, :current_user}, AlgoraWeb.Nav] do
      live "/", HomeLive, :show
      live "/partner", PartnerLive, :show
      live "/:channel_handle/ads", AdOverlayLive, :show
    end

    live_session :chat,
      layout: {AlgoraWeb.Layouts, :live_chat},
      root_layout: {AlgoraWeb.Layouts, :root_embed},
      on_mount: [{AlgoraWeb.UserAuth, :current_user}, AlgoraWeb.Nav] do
      live "/:channel_handle/chat", ChatLive, :show
      live "/:channel_handle/:video_id/chat", ChatLive, :show
      live "/:channel_handle/:video_id/chat_popout", ChatPopoutLive, :show
    end
  end

  scope "/docs" do
    pipe_through [:transform_docs]

    forward "/", ReverseProxyPlug,
      upstream: "#{Application.compile_env(:algora, :docs)[:url]}/docs",
      response_mode: :buffer
  end

  scope "/", AlgoraWeb do
    pipe_through :browser

    get "/go/:slug", AdRedirectController, :go

    delete "/auth/logout", OAuthCallbackController, :sign_out

    live_session :schedule,
      on_mount: [{AlgoraWeb.UserAuth, :current_user}, AlgoraWeb.Nav] do
      live "/ads/schedule", AdLive.Schedule, :schedule
      live "/analytics/:slug", AdLive.Analytics, :show
    end

    live_session :admin,
      on_mount: [
        {AlgoraWeb.UserAuth, :ensure_authenticated},
        {AlgoraWeb.UserAuth, :ensure_admin},
        AlgoraWeb.Nav
      ] do
      live "/shows", ShowLive.Index, :index
      live "/shows/new", ShowLive.Index, :new

      live "/ads", AdLive.Index, :index
      live "/ads/new", AdLive.Index, :new
      live "/ads/:id/edit", AdLive.Index, :edit
      live "/ads/:id", AdLive.Show, :show
      live "/ads/:id/show/edit", AdLive.Show, :edit

      live "/admin/content", ContentLive, :show
    end

    live_session :authenticated,
      on_mount: [{AlgoraWeb.UserAuth, :ensure_authenticated}, AlgoraWeb.Nav] do
      live "/subscriptions", SubscriptionsLive, :show

      live "/channel/settings", SettingsLive, :edit
      live "/channel/studio", StudioLive, :show
      live "/channel/studio/upload", StudioLive, :upload
      live "/channel/audience", AudienceLive, :show
      live "/:channel_handle/stream", ChannelLive, :stream

      live "/videos/:video_id/subtitles", SubtitleLive.Index, :index
      live "/videos/:video_id/subtitles/new", SubtitleLive.Index, :new
      live "/videos/:video_id/subtitles/:id", SubtitleLive.Show, :show
      live "/videos/:video_id/subtitles/:id/edit", SubtitleLive.Index, :edit
      live "/videos/:video_id/subtitles/:id/show/edit", SubtitleLive.Show, :edit
    end

    live_session :default, on_mount: [{AlgoraWeb.UserAuth, :current_user}, AlgoraWeb.Nav] do
      live "/cossgpt", COSSGPTLive, :index
      live "/og/cossgpt", COSSGPTOGLive, :index

      live "/shows/:slug", ShowLive.Show, :show
      live "/shows/:slug/edit", ShowLive.Show, :edit

      live "/:channel_handle", ChannelLive, :show
      live "/:channel_handle/:video_id", VideoLive, :show

      get "/shows/:slug/event.ics", ShowCalendarController, :export

      get "/gh/:user_id/thumbnail", GithubController, :get_thumbnail
      get "/gh/:user_id/channel", GithubController, :get_channel
    end
  end
end
