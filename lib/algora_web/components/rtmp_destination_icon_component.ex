defmodule AlgoraWeb.RTMPDestinationIconComponent do
  use Phoenix.Component

  @domain_icon_map %{
    "youtube.com" => :youtube,
    "youtu.be" => :youtube,
    "live-video.net" => :twitch,
    "twitch.tv" => :twitch,
    "twitch.com" => :twitch,
    "pscp.tv" => :x,
    "twitter.com" => :x,
    "x.com" => :x
  }

  attr :url, :string
  attr :class, :string, default: nil

  def render(assigns) do
    ~H"""
    <%= case get_icon(@url) do %>
      <% :twitch -> %>
        <svg
          xmlns="http://www.w3.org/2000/svg"
          width="24"
          height="24"
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          stroke-width="2"
          stroke-linecap="round"
          stroke-linejoin="round"
          class={["text-purple-400", @class]}
        >
          <path stroke="none" d="M0 0h24v24H0z" fill="none" /><path d="M4 5v11a1 1 0 0 0 1 1h2v4l4 -4h5.584c.266 0 .52 -.105 .707 -.293l2.415 -2.414c.187 -.188 .293 -.442 .293 -.708v-8.585a1 1 0 0 0 -1 -1h-14a1 1 0 0 0 -1 1z" /><path d="M16 8l0 4" /><path d="M12 8l0 4" />
        </svg>
      <% :youtube -> %>
        <svg
          xmlns="http://www.w3.org/2000/svg"
          width="24"
          height="24"
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          stroke-width="2"
          stroke-linecap="round"
          stroke-linejoin="round"
          class={["text-red-400", @class]}
        >
          <path stroke="none" d="M0 0h24v24H0z" fill="none" /><path d="M2 8a4 4 0 0 1 4 -4h12a4 4 0 0 1 4 4v8a4 4 0 0 1 -4 4h-12a4 4 0 0 1 -4 -4v-8z" /><path d="M10 9l5 3l-5 3z" />
        </svg>
      <% :x -> %>
        <svg
          xmlns="http://www.w3.org/2000/svg"
          width="24"
          height="24"
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          stroke-width="2"
          stroke-linecap="round"
          stroke-linejoin="round"
          class={["text-white", @class]}
        >
          <path stroke="none" d="M0 0h24v24H0z" fill="none" /><path d="M4 4l11.733 16h4.267l-11.733 -16z" /><path d="M4 20l6.768 -6.768m2.46 -2.46l6.772 -6.772" />
        </svg>
      <% _ -> %>
        <svg
          xmlns="http://www.w3.org/2000/svg"
          width="24"
          height="24"
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          stroke-width="2"
          stroke-linecap="round"
          stroke-linejoin="round"
          class={["text-green-400", @class]}
        >
          <path stroke="none" d="M0 0h24v24H0z" fill="none" /><path d="M18.364 19.364a9 9 0 1 0 -12.728 0" /><path d="M15.536 16.536a5 5 0 1 0 -7.072 0" /><path d="M12 13m-1 0a1 1 0 1 0 2 0a1 1 0 1 0 -2 0" />
        </svg>
    <% end %>
    """
  end

  defp get_icon(url) do
    host = URI.parse(url).host

    @domain_icon_map
    |> Enum.find_value(:broadcast, fn {domain, icon} ->
      if String.ends_with?(host, domain), do: icon
    end)
  end
end
