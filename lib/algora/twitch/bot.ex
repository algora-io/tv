defmodule Algora.Twitch.Bot do
  use TMI

  @impl TMI.Handler
  def handle_message("!" <> command, sender, chat) do
    case command do
      "dice" ->
        say(chat, Enum.random(~w(⚀ ⚁ ⚂ ⚃ ⚄ ⚅)))

      "echo " <> rest ->
        say(chat, rest)

      "dance" ->
        me(chat, "dances for #{sender}")

      _ ->
        say(chat, "unrecognized command")
    end
  end

  def handle_message(message, sender, chat) do
    dbg(message)
    Logger.debug("Message in #{chat} from #{sender}: #{message}")
  end
end
