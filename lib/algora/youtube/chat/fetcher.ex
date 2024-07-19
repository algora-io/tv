defmodule Algora.Youtube.Chat.Fetcher do
  use GenServer
  require Logger

  alias Algora.Youtube
  alias Algora.{Accounts, Chat}

  @youtube_api "https://www.youtube.com/youtubei/v1/live_chat/get_live_chat?key="
  # you can adjust the interval
  @chat_interval :timer.seconds(2)

  # Client API
  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def fetch_chat(continuation_token) do
    GenServer.call(__MODULE__, {:fetch_chat, continuation_token})
  end

  # Server Callbacks
  def init(args) do
    Process.send_after(self(), {:init, args}, 0)
    {:ok, %{}}
  end

  def handle_info({:init, %{youtube_handle: youtube_handle, video: video}}, state) do
    {:ok, res} = Youtube.Chat.get_video_data(["https://www.youtube.com/#{youtube_handle}/live"])
    %{config: config, initial_data: initial_data} = res

    continuation =
      Youtube.Chat.find_key_value(initial_data, "title", "Live chat")
      |> then(& &1["continuation"])
      |> Youtube.Chat.get_continuation_token()

    if continuation do
      Process.send_after(self(), {:fetch_chat, continuation}, 0)

      {:noreply,
       %{
         video: video,
         config: config,
         seen_messages: %{},
         next_continuation_token: nil
       }}
    else
      {:stop, :shutdown, state}
    end
  end

  def handle_info({:fetch_chat, continuation_token}, state) do
    next_token = fetch_chat_internal(continuation_token, state)
    state = %{state | next_continuation_token: next_token}

    Process.send_after(self(), {:fetch_chat, next_token}, @chat_interval)

    {:noreply, state}
  end

  def handle_call({:fetch_chat, continuation_token}, _from, state) do
    next_token = fetch_chat_internal(continuation_token, state)
    state = %{state | next_continuation_token: next_token}

    Process.send_after(self(), {:fetch_chat, next_token}, @chat_interval)

    {:reply, :ok, state}
  end

  defp fetch_chat_internal(continuation_token, state) do
    next_token = continuation_token

    url = "#{@youtube_api}#{state.config["INNERTUBE_API_KEY"]}"

    body =
      Jason.encode!(%{
        context: state.config["INNERTUBE_CONTEXT"],
        continuation: continuation_token,
        webClientInfo: %{isDocumentHidden: false}
      })

    with {:ok, %HTTPoison.Response{status_code: 200, body: body}} <-
           HTTPoison.post(url, body, [{"Content-Type", "application/json"}]),
         {:ok, data} <- Jason.decode(body) do
      next_continuation =
        get_in(data, [
          "continuationContents",
          "liveChatContinuation",
          "continuations",
          Access.at(0)
        ])

      next_token =
        (next_continuation && Youtube.Chat.get_continuation_token(next_continuation)) ||
          continuation_token

      actions = get_in(data, ["continuationContents", "liveChatContinuation", "actions"]) || []

      Enum.each(actions, fn action ->
        id = Youtube.Chat.get_id(action)

        if id && !Map.has_key?(state.seen_messages, id) do
          state = %{
            state
            | seen_messages: Map.put(state.seen_messages, id, :os.system_time(:seconds))
          }

          process_action(action, state)
        end
      end)

      next_token
    else
      {:error, %HTTPoison.Error{reason: reason}} ->
        IO.puts("HTTP error: #{reason}")
        next_token

      _ ->
        continuation_token
    end
  end

  def process_action(
        %{
          "addChatItemAction" => %{
            "item" => %{
              "liveChatTextMessageRenderer" => %{
                "authorExternalChannelId" => author_id,
                "authorName" => %{"simpleText" => name},
                "authorPhoto" => %{"thumbnails" => [%{"url" => avatar_url} | _]},
                "id" => message_id,
                "message" => %{"runs" => [%{"text" => body}]},
                "timestampUsec" => _timestamp
              }
            }
          }
        } = payload,
        state
      ) do
    unless Chat.get_message_by(platform_id: message_id) do
      entity =
        Accounts.get_or_create_entity!(%{
          name: name,
          handle: Slug.slugify(name),
          avatar_url: avatar_url,
          platform: "youtube",
          platform_id: author_id
        })

      case Chat.create_message(entity, state.video, %{body: body, platform_id: message_id}) do
        {:ok, message} ->
          # HACK:
          message = Chat.get_message!(message.id)
          Chat.broadcast_message_sent!(message)

        _error ->
          Logger.error("Failed to persist payload: #{inspect(payload)}")
      end
    end
  end

  def process_action(_action, _state), do: :ok
end
