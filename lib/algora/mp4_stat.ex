defmodule Algora.MP4Stat do
  alias Algora.MP4Stat

  defstruct size: 0, title: nil

  def parse(path) do
    stat = File.stat!(path)
    {:ok, %MP4Stat{size: stat.size}}
  end
end
