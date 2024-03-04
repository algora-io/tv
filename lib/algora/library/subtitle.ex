defmodule Algora.Library.Subtitle do
  use Ecto.Schema
  import Ecto.Changeset

  schema "subtitles" do
    field :start, :float
    field :end, :float
    field :body, :string
    belongs_to :video, Library.Video

    timestamps()
  end

  @doc false
  def changeset(subtitle, attrs) do
    subtitle
    |> cast(attrs, [:body, :start, :end])
    |> validate_required([:body, :start, :end])
  end
end
