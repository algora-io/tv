defmodule Algora.Utils.PathValidation do
  @moduledoc false

  @spec inside_directory?(Path.t(), Path.t()) :: boolean()
  def inside_directory?(path, directory) do
    relative_path = Path.relative_to(path, directory)
    relative_path != path and relative_path != "."
  end
end
