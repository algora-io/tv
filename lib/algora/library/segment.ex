defmodule Algora.Library.Segment do
  alias Algora.Library
  alias Algora.Library.{Segment, Subtitle}
  use Ecto.Schema
  import Ecto.Changeset

  schema "segments" do
    field :start, :float
    field :end, :float
    field :body, :string
    field :embedding, :map
    belongs_to :video, Library.Video
    belongs_to :starting_subtitle, Library.Subtitle
    belongs_to :ending_subtitle, Library.Subtitle

    timestamps()
  end

  @doc false
  def changeset(segment, attrs) do
    segment
    |> cast(attrs, [:body, :start, :end])
    |> validate_required([:body, :start, :end])
  end

  def init([]), do: nil

  def init(subtitles) do
    body = subtitles |> Enum.map_join("", fn %Subtitle{body: body} -> body end)
    starting_subtitle = subtitles |> Enum.at(0)
    ending_subtitle = subtitles |> Enum.at(-1)

    %Segment{
      body: body,
      start: starting_subtitle.start,
      end: ending_subtitle.end,
      video_id: starting_subtitle.video_id,
      starting_subtitle_id: starting_subtitle.id,
      ending_subtitle_id: ending_subtitle.id
    }
  end
end
