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

  defmodule TransmuxingQueued do
    defstruct video: nil
  end

  defmodule TransmuxingProgressed do
    defstruct video: nil, pct: nil
  end

  defmodule TransmuxingCompleted do
    defstruct video: nil, url: nil
  end
end
