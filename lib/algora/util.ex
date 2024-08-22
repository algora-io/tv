defmodule Algora.Util do
  @common_words [
    "a",
    "add",
    "again",
    "air",
    "also",
    "an",
    "and",
    "are",
    "as",
    "ask",
    "at",
    "be",
    "but",
    "by",
    "can",
    "do",
    "does",
    "each",
    "end",
    "even",
    "for",
    "from",
    "get",
    "got",
    "had",
    "have",
    "he",
    "here",
    "his",
    "how",
    "i",
    "if",
    "in",
    "is",
    "it",
    "kind",
    "men",
    "must",
    "my",
    "near",
    "need",
    "of",
    "off",
    "on",
    "one",
    "or",
    "other",
    "our",
    "out",
    "put",
    "said",
    "self",
    "set",
    "some",
    "such",
    "tell",
    "that",
    "the",
    "their",
    "they",
    "this",
    "to",
    "try",
    "us",
    "use",
    "want",
    "was",
    "we're",
    "we",
    "well",
    "went",
    "were",
    "what",
    "which",
    "why",
    "will",
    "with",
    "you're",
    "you",
    "your"
  ]

  def app_url() do
    config = Application.get_env(:algora, AlgoraWeb.Endpoint)

    scheme =
      case Application.get_env(:algora, :mode) do
        :prod -> "https"
        _ -> "http"
      end

    host = config[:url][:host] || "localhost"
    port = config[:http][:port]

    "#{scheme}://#{host}#{port_string(scheme, port)}"
  end

  defp port_string("http", 80), do: ""
  defp port_string("https", 443), do: ""
  defp port_string(_, port), do: ":#{port}"

  def common_word?(s), do: Enum.member?(@common_words, s)

  def random_string do
    binary = <<
      System.system_time(:nanosecond)::64,
      :erlang.phash2({node(), self()})::16,
      :erlang.unique_integer()::16
    >>

    binary
    |> Base.url_encode64()
    |> String.replace(["/", "+"], "-")
  end
end
