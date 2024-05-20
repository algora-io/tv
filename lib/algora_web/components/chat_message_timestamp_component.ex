defmodule AlgoraWeb.ChatMessageTimestampComponent do
  use AlgoraWeb, :live_component

  def render(assigns) do
    ~H"""
    <span class="text-gray-400 text-xs ml-1">
      <%= format_timestamp(@message.inserted_at) %>
    </span>
    """
  end

  defp format_timestamp(timestamp) do
    now = NaiveDateTime.utc_now()
    diff_in_seconds = NaiveDateTime.diff(now, timestamp)

    cond do
      diff_in_seconds < 60 -> "Just now"
      diff_in_seconds < 3600 -> "#{div(diff_in_seconds, 60)}m ago"
      diff_in_seconds < 86_400 -> "#{div(diff_in_seconds, 3600)}h ago"
      diff_in_seconds < 604_800 -> "#{div(diff_in_seconds, 86400)}d ago"
      true -> Calendar.strftime(timestamp, "%b %-d, %Y")
    end
  end
end
