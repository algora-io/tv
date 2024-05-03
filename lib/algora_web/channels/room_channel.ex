defmodule AlgoraWeb.RoomChannel do
  alias Algora.Chat.Message
  alias Algora.Repo

  use Phoenix.Channel

  def join("room:" <> _room_id, _params, socket) do
    {:ok, socket}
  end

  def handle_in("new_msg", %{"body" => body}, socket) do
    user = socket.assigns.user
    "room:" <> video_id = socket.topic

    if user do
      message =
        Repo.insert!(%Message{
          body: body,
          user_id: user.id,
          video_id: String.to_integer(video_id)
        })

      broadcast!(socket, "new_msg", %{
        user: %{id: user.id, handle: user.handle},
        id: message.id,
        body: body
      })
    end

    {:noreply, socket}
  end
end
