defmodule AlgoraWeb.SubtitleLive.Index do
  use AlgoraWeb, :live_view

  alias Algora.Library
  alias Algora.Library.Subtitle

  @impl true
  def mount(%{"video_id" => video_id}, _session, socket) do
    video = Library.get_video!(video_id)

    {:ok,
     socket
     |> assign(:video, video)
     |> stream(:subtitles, Library.list_subtitles(video))}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Subtitle")
    |> assign(:subtitle, Library.get_subtitle!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Subtitle")
    |> assign(:subtitle, %Subtitle{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Subtitles")
    |> assign(:subtitle, nil)
  end

  @impl true
  def handle_info({AlgoraWeb.SubtitleLive.FormComponent, {:saved, subtitle}}, socket) do
    {:noreply, stream_insert(socket, :subtitles, subtitle)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    subtitle = Library.get_subtitle!(id)
    {:ok, _} = Library.delete_subtitle(subtitle)

    {:noreply, stream_delete(socket, :subtitles, subtitle)}
  end
end
