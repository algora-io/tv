defmodule Algora.Library.Subtitle do
  alias Algora.Library
  use Ecto.Schema
  import Ecto.Changeset

  @type t() :: %__MODULE__{}

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
