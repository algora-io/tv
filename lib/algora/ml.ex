defmodule Algora.ML do
  alias Replicate.Predictions
  alias Replicate.Predictions.Prediction
  alias Algora.Cache

  @chunk_size 400

  @mistral "mistralai/Mixtral-8x7B-Instruct-v0.1"
  @mpnet "replicate/all-mpnet-base-v2"
  @whisper "vaibhavs10/incredibly-fast-whisper"

  @mistral_version ""
  @mpnet_version "b6b7585c9640cd7a9572c6e129c9549d79c9c31f0d3fdce7baac7c67ca38f305"
  @whisper_version "3ab86df6c8f54c11309d4d1f930ac292bad43ace52d10c80d87eb258b3c9f79c"

  def get!(id), do: Predictions.get!(id)

  defp index_path(), do: Cache.path("hnswlib/index")

  def save_index(index) do
    HNSWLib.Index.save_index(index, index_path())
  end

  def load_index!() do
    case HNSWLib.Index.load_index(:cosine, 768, index_path(), max_elements: 1_000_000) do
      {:ok, index} ->
        index

      {:error, _} ->
        {:ok, index} = HNSWLib.Index.new(:cosine, 768, 1_000_000)
        save_index(index)
        index
    end
  end

  def add_embeddings(index, %Prediction{output: output}) do
    for x <- output do
      HNSWLib.Index.add_items(index, Nx.tensor(x["embedding"]))
    end

    save_index(index)
  end

  def get_relevant_chunks(index, chunks, embedding) do
    {:ok, labels, _dist} =
      HNSWLib.Index.knn_query(index, Nx.tensor(embedding), k: 3)

    IO.puts("")

    labels
    |> Nx.to_flat_list()
    |> Enum.map_join("\n\n", fn idx -> "[...] " <> Enum.at(chunks, idx) <> " [...]" end)
  end

  def transcribe_video_async(path) do
    run_async(
      @whisper,
      @whisper_version,
      audio: path,
      language: "english",
      timestamp: "chunk",
      batch_size: 64,
      diarise_audio: false
    )
  end

  def create_embeddings(chunks) do
    run(@mpnet, @mpnet_version, text_batch: Jason.encode!(chunks))
  end

  def create_embeddings_async(chunks) do
    run_async(@mpnet, @mpnet_version, text_batch: Jason.encode!(chunks))
  end

  def test do
    Regex.named_captures(
      ~r/^(?P<model>[^\/]+\/[^:]+):(?P<version>.+)$/,
      "replicate/all-mpnet-base-v2"
    )
  end

  def run(model, version, input) do
    case Replicate.run("#{model}:#{version}", input) do
      {:ok, %Prediction{} = prediction} -> prediction
      {:error, message} -> {:error, message}
    end
  end

  def run_async(model, version, input) do
    model = Replicate.Models.get!(model)
    version = Replicate.Models.get_version!(model, version)

    case Predictions.create(version, input) do
      {:ok, %Prediction{} = prediction} -> prediction
      {:error, message} -> {:error, message}
    end
  end

  def fetch_output!(%Prediction{output: output}) do
    {:ok, resp} = Finch.build(:get, output) |> Finch.request(Algora.Finch)
    Jason.decode!(resp.body)
  end

  def load_tokenizer!() do
    {:ok, tokenizer} = Bumblebee.load_tokenizer({:hf, @mistral}, [{:type, :llama}])
    tokenizer
  end

  def tokenize_and_measure(tokenizer, input) do
    %{"input_ids" => tensor} = Bumblebee.apply_tokenizer(tokenizer, input)
    {1, len} = Nx.shape(tensor)
    len
  end

  def chunk(text), do: chunk(load_tokenizer!(), [], "", text |> String.graphemes())

  def chunk(_, chunks, [], []), do: Enum.reverse(chunks)

  def chunk(tokenizer, chunks, chunk, []), do: chunk(tokenizer, [chunk | chunks], [], [])

  # HACK: loops forever when given a word that doesn't fit in a chunk
  # TODO: overlap chunks
  # TODO: ensure each chunk contains content from one speaker only
  def chunk(tokenizer, chunks, chunk, graphemes) do
    next_index = Enum.find_index(graphemes, &is_whitespace?/1)

    {head, rest} =
      case next_index do
        nil -> {graphemes, []}
        idx -> Enum.split(graphemes, idx + 1)
      end

    new_chunk = (chunk <> to_string(head)) |> dbg
    is_valid? = tokenize_and_measure(tokenizer, new_chunk) <= @chunk_size

    if is_valid? do
      chunk(tokenizer, chunks, new_chunk, rest)
    else
      chunk(tokenizer, [new_chunk | chunks], "", graphemes)
    end
  end

  # HACK: implement properly
  defp is_whitespace?(s), do: s == "\n" or s == " "
end
