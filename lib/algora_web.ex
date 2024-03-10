defmodule AlgoraWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, views, channels and so on.

  This can be used in your application as:

      use AlgoraWeb, :controller
      use AlgoraWeb, :html

  The definitions below will be executed for every view,
  controller, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define any helper function in modules
  and import those modules here.
  """

  def static_paths, do: ~w(assets fonts images favicon.ico robots.txt)

  def controller do
    quote do
      use Phoenix.Controller,
        namespace: AlgoraWeb,
        formats: [:html, :json],
        layouts: [html: AlgoraWeb.Layouts]

      import Plug.Conn
      import AlgoraWeb.Gettext
      alias AlgoraWeb.Router.Helpers, as: Routes
      unquote(verified_routes())
    end
  end

  def html do
    quote do
      use Phoenix.Component

      # Import convenience functions from controllers
      import Phoenix.Controller,
        only: [get_csrf_token: 0, view_module: 1, view_template: 1]

      # Include general helpers for rendering HTML
      unquote(html_helpers())
    end
  end

  def verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: AlgoraWeb.Endpoint,
        router: AlgoraWeb.Router,
        statics: AlgoraWeb.static_paths()
    end
  end

  def live_view(opts \\ []) do
    quote do
      @opts Keyword.merge(
              [
                layout: {AlgoraWeb.Layouts, :live},
                container: {:div, class: "relative flex"}
              ],
              unquote(opts)
            )
      use Phoenix.LiveView, @opts

      unquote(html_helpers())
    end
  end

  def live_component do
    quote do
      use Phoenix.LiveComponent

      unquote(html_helpers())
    end
  end

  def router do
    quote do
      use Phoenix.Router, helpers: false

      import Plug.Conn
      import Phoenix.Controller
      import Phoenix.LiveView.Router
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
      import AlgoraWeb.Gettext
    end
  end

  defp html_helpers do
    quote do
      import Phoenix.HTML
      import Phoenix.HTML.Form
      # TODO: is this needed?
      use PhoenixHTMLHelpers

      # Import LiveView and .heex helpers (live_render, live_patch, <.form>, etc)
      use Phoenix.Component

      import AlgoraWeb.CoreComponents
      import AlgoraWeb.Gettext
      alias AlgoraWeb.Router.Helpers, as: Routes
      alias Phoenix.LiveView.JS
      unquote(verified_routes())
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__({which, opts}) when is_atom(which) do
    apply(__MODULE__, which, [opts])
  end

  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
