defmodule Algora.Library.Events do
  defmodule LivestreamStarted do
    defstruct video: nil, resume: false
  end

  defmodule LivestreamEnded do
    defstruct video: nil, resume: false
  end

  defmodule ThumbnailsGenerated do
    defstruct video: nil
  end

  defmodule ProcessingQueued do
    defstruct video: nil
  end

  defmodule ProcessingProgressed do
    defstruct video: nil, stage: nil, pct: nil
  end

  defmodule ProcessingCompleted do
    defstruct video: nil, action: nil, url: nil
  end

  defmodule ProcessingFailed do
    defstruct video: nil, attempt: nil, max_attempts: nil
  end
end
