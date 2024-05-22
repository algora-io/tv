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
    "x.com" => :x,
    "azure.net" => :linkedin,
    "linkedin.com" => :linkedin,
    "linked.in" => :linkedin
  }

  attr :url, :string
  attr :class, :string, default: nil

  def render(assigns) do
    ~H"""
    <.icon icon={get_icon(@url)} class={@class} />
    """
  end

  attr :icon, :atom
  attr :class, :string, default: nil

  def icon(assigns) do
    ~H"""
    <%= case @icon do %>
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
      <% :linkedin -> %>
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 72 72" class={[@class]}>
          <g fill="none" fill-rule="evenodd">
            <path
              d="M8,72 L64,72 C68.418278,72 72,68.418278 72,64 L72,8 C72,3.581722 68.418278,-8.11624501e-16 64,0 L8,0 C3.581722,8.11624501e-16 -5.41083001e-16,3.581722 0,8 L0,64 C5.41083001e-16,68.418278 3.581722,72 8,72 Z"
              fill="#007EBB"
            /><path
              d="M62,62 L51.315625,62 L51.315625,43.8021149 C51.315625,38.8127542 49.4197917,36.0245323 45.4707031,36.0245323 C41.1746094,36.0245323 38.9300781,38.9261103 38.9300781,43.8021149 L38.9300781,62 L28.6333333,62 L28.6333333,27.3333333 L38.9300781,27.3333333 L38.9300781,32.0029283 C38.9300781,32.0029283 42.0260417,26.2742151 49.3825521,26.2742151 C56.7356771,26.2742151 62,30.7644705 62,40.051212 L62,62 Z M16.349349,22.7940133 C12.8420573,22.7940133 10,19.9296567 10,16.3970067 C10,12.8643566 12.8420573,10 16.349349,10 C19.8566406,10 22.6970052,12.8643566 22.6970052,16.3970067 C22.6970052,19.9296567 19.8566406,22.7940133 16.349349,22.7940133 Z M11.0325521,62 L21.769401,62 L21.769401,27.3333333 L11.0325521,27.3333333 L11.0325521,62 Z"
              fill="#FFF"
            />
          </g>
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
