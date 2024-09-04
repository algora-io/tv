defmodule Algora.Admin.ReplaceWithYoutube do
  alias Algora.Repo
  alias Algora.Accounts.User
  alias Algora.Library.Video
  alias Algora.Ads.{Appearance, ContentMetrics, ProductReview}
  alias Algora.Chat.Message
  alias Algora.Library.{Segment, Subtitle}
  alias Algora.Library

  import Ecto.Query

  # Algora.Admin.ReplaceWithYoutube.run("""
  # 2024-08-27,heyandras,4:49:14,https://www.youtube.com/watch?v=ooMn-3ISOmI
  # 2024-08-30,heyandras,5:34:09,https://www.youtube.com/watch?v=RtYlh3ze0EI
  # 2024-09-02,heyandras,6:03:05,https://www.youtube.com/watch?v=X958aGE5NfI
  # 2024-09-03,heyandras,5:50:26,https://www.youtube.com/watch?v=xO0plZnHKMg
  # """)

  def run(input) do
    input
    |> String.split("\n", trim: true)
    |> Enum.each(&process_line/1)
  end

  defp process_line(line) do
    [date, handle, duration, youtube_url] = String.split(line, ",", trim: true)
    user = Repo.get_by!(User, handle: handle)

    date = Date.from_iso8601!(date)
    duration_seconds = Library.from_hhmmss(duration)

    old_videos = find_videos(user.id, date)

    new_video = create_youtube_video(user.id, duration_seconds, youtube_url, old_videos)

    transfer_related_records(old_videos, new_video)

    delete_old_videos(old_videos)
  end

  defp create_youtube_video(user_id, duration_seconds, youtube_url, old_videos) do
    video_id = extract_youtube_id(youtube_url)

    %Video{
      user_id: user_id,
      inserted_at: get_date_from_old_videos(old_videos),
      duration: duration_seconds,
      url: youtube_url,
      format: :youtube,
      type: :vod,
      uuid: Ecto.UUID.generate(),
      title: get_title_from_old_videos(old_videos),
      thumbnail_url: "https://i.ytimg.com/vi/#{video_id}/maxresdefault.jpg"
    }
    |> Repo.insert!()
  end

  defp get_title_from_old_videos([first_video | _]), do: first_video.title
  defp get_date_from_old_videos([first_video | _]), do: first_video.inserted_at

  defp find_videos(user_id, date) do
    Video
    |> where([v], v.user_id == ^user_id)
    |> where([v], fragment("DATE(inserted_at) = ?", ^date))
    |> Repo.all()
  end

  defp transfer_related_records(old_videos, new_video) do
    old_video_ids = Enum.map(old_videos, & &1.id)

    transfer_appearances(old_video_ids, new_video.id)
    transfer_content_metrics(old_video_ids, new_video.id)
    transfer_product_reviews(old_video_ids, new_video.id)
    transfer_messages(old_video_ids, new_video.id)
    transfer_segments(old_video_ids, new_video.id)
    transfer_subtitles(old_video_ids, new_video.id)
  end

  defp transfer_appearances(old_video_ids, new_video_id) do
    from(a in Appearance, where: a.video_id in ^old_video_ids)
    |> Repo.update_all(set: [video_id: new_video_id])
  end

  defp transfer_content_metrics(old_video_ids, new_video_id) do
    from(cm in ContentMetrics, where: cm.video_id in ^old_video_ids)
    |> Repo.update_all(set: [video_id: new_video_id])
  end

  defp transfer_product_reviews(old_video_ids, new_video_id) do
    from(pr in ProductReview, where: pr.video_id in ^old_video_ids)
    |> Repo.update_all(set: [video_id: new_video_id])
  end

  defp transfer_messages(old_video_ids, new_video_id) do
    from(m in Message, where: m.video_id in ^old_video_ids)
    |> Repo.update_all(set: [video_id: new_video_id])
  end

  defp transfer_segments(old_video_ids, new_video_id) do
    from(s in Segment, where: s.video_id in ^old_video_ids)
    |> Repo.update_all(set: [video_id: new_video_id])
  end

  defp transfer_subtitles(old_video_ids, new_video_id) do
    from(s in Subtitle, where: s.video_id in ^old_video_ids)
    |> Repo.update_all(set: [video_id: new_video_id])
  end

  defp delete_old_videos(old_videos) do
    Enum.each(old_videos, &Library.delete_video/1)
  end

  defp extract_youtube_id(url) do
    url
    |> URI.parse()
    |> Map.get(:query)
    |> URI.decode_query()
    |> Map.get("v")
  end
end
