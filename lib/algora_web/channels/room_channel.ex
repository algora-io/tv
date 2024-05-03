defmodule AlgoraWeb.RoomChannel do
  alias Algora.Chat.Message
  alias Algora.Repo
  alias Algora.Library

  use Phoenix.Channel

  def join("room:" <> _room_id, _params, socket) do
    {:ok, socket}
  end

  def handle_in("new_msg", %{"body" => body}, socket) do
    user = socket.assigns.user
    "room:" <> video_id = socket.topic

    if user do
      video = Library.get_video!(String.to_integer(video_id))

      message =
        Repo.insert!(%Message{
          body: body,
          user_id: user.id,
          video_id: video.id
        })

      broadcast!(socket, "new_msg", %{
        user: %{id: user.id, handle: user.handle},
        id: message.id,
        body: body
      })

      Library.broadcast_message_sent!(video.user_id, message)
    end

    {:noreply, socket}
  end
end
