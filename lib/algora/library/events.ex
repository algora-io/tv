defmodule Algora.Library.Events do
  defmodule LivestreamStarted do
    defstruct video: nil
  end

  defmodule LivestreamEnded do
    defstruct video: nil
  end

  defmodule ThumbnailsGenerated do
    defstruct video: nil
  end
end
