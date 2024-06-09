defmodule AlgoraWeb.Nav do
  import Phoenix.LiveView
  use Phoenix.Component

  alias Algora.{Library}
  alias AlgoraWeb.{ChannelLive, HomeLive, SettingsLive}

  def on_mount(:default, _params, _session, socket) do
    {:cont,
     socket
     |> assign(active_users: Library.list_active_channels(limit: 20))
     |> assign(:region, System.get_env("FLY_REGION") || "iad")
     |> attach_hook(:active_tab, :handle_params, &handle_active_tab_params/3)}
  end

  defp handle_active_tab_params(params, _url, socket) do
    active_tab =
      case {socket.view, socket.assigns.live_action} do
        {ChannelLive, _} ->
          if params["channel_handle"] == current_user_channel_handle(socket) do
            :channel
          end

        {HomeLive, _} ->
          :home

        {SettingsLive, _} ->
          :settings

        {_, _} ->
          nil
      end

    {:cont, assign(socket, active_tab: active_tab)}
  end

  defp current_user_channel_handle(socket) do
    if user = socket.assigns.current_user do
      user.handle
    end
  end
end
