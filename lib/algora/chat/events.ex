defmodule Algora.Chat.Events do
  defmodule MessageSent do
    defstruct message: nil
  end

  defmodule MessageDeleted do
    defstruct message: nil
  end
end
