defmodule AlgoraWeb.ShowCalendarController do
  use AlgoraWeb, :controller

  alias Algora.{Shows, Accounts, Library}

  def export(conn, %{"slug" => slug} = params) do
    case Shows.get_show_by_fields!(slug: slug) do
      nil ->
        send_resp(conn, 404, "Not found")

      show when show.scheduled_for == nil ->
        send_resp(conn, 404, "Not found")

      show ->
        channel = Accounts.get_user!(show.user_id) |> Library.get_channel!()
        url = show.url || "#{AlgoraWeb.Endpoint.url()}/#{channel.handle}/latest"

        start_date =
          show.scheduled_for
          |> Timex.to_datetime("Etc/UTC")
          |> Timex.Timezone.convert(params["tz"] || "Etc/UTC")

        end_date = DateTime.add(start_date, 3600)

        events = [
          %ICalendar.Event{
            summary: show.title,
            dtstart: start_date,
            dtend: end_date,
            description: show.description,
            location: url,
            url: url,
            organizer: channel.name
          }
        ]

        ics = %ICalendar{events: events} |> ICalendar.to_ics()

        conn
        |> put_resp_content_type("text/calendar")
        |> put_resp_header("content-disposition", "attachment; filename=#{show.slug}.ics")
        |> Plug.Conn.send_resp(:ok, ics)
    end
  end
end
