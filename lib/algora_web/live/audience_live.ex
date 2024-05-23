defmodule AlgoraWeb.AudienceLive do
  use AlgoraWeb, :live_view
  import Ecto.Query, warn: false

  alias Algora.Library.Event
  alias Algora.Repo

  def render(assigns) do
    ~H"""
    <div>
      <h1>Audience</h1>
      <h2>Unique Watchers</h2>
      <table>
        <%= for watcher <- @watchers do %>
          <tr>
            <td><%= watcher.actor_id %></td>
          </tr>
        <% end %>
      </table>
      <h2>Unique Subscribers</h2>
      <table>
        <%= for subscriber <- @subscribers do %>
          <tr>
            <td><%= subscriber.actor_id %></td>
          </tr>
        <% end %>
      </table>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    watchers = fetch_unique_watchers(user)
    subscribers = fetch_unique_subscribers(user)

    {:ok, assign(socket, watchers: watchers, subscribers: subscribers)}
  end

  defp fetch_unique_watchers(user) do
    Event
    |> where([e], e.channel_id == ^user.id and e.name == :watched)
    |> distinct([e], e.actor_id)
    |> Repo.all()
  end

  defp fetch_unique_subscribers(user) do
    # TODO: exclude unsubscribers
    Event
    |> where([e], e.channel_id == ^user.id and e.name == :subscribed)
    |> distinct([e], e.actor_id)
    |> Repo.all()
  end
end
