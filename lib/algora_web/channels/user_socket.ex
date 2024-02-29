defmodule AlgoraWeb.UserSocket do
  use Phoenix.Socket
  alias Algora.Accounts

  channel "room:*", AlgoraWeb.RoomChannel

  @impl true
  def connect(%{"token" => token}, socket, _connect_info) do
    # max_age: 1209600 is equivalent to two weeks in seconds
    case Phoenix.Token.verify(socket, "user socket", token, max_age: 1_209_600) do
      {:ok, 0} ->
        {:ok, socket}

      {:ok, user_id} ->
        user = Accounts.get_user(user_id)
        {:ok, assign(socket, :user, user)}

      {:error, _} = error ->
        error
    end
  end

  # Socket id's are topics that allow you to identify all sockets for a given user:
  #
  #     def id(socket), do: "user_socket:#{socket.assigns.user_id}"
  #
  # Would allow you to broadcast a "disconnect" event and terminate
  # all active sockets and channels for a given user:
  #
  #     Elixir.AlgoraWeb.Endpoint.broadcast("user_socket:#{user.id}", "disconnect", %{})
  #
  # Returning `nil` makes this socket anonymous.
  @impl true
  def id(_socket), do: nil
end
