defmodule Algora.ML do
  alias Replicate.Predictions
  alias Replicate.Predictions.Prediction
  alias Algora.{Cache, Library}

  @chunk_size 128

  @mistral "mistralai/Mixtral-8x7B-Instruct-v0.1"
  @mpnet "replicate/all-mpnet-base-v2"
  @whisper "vaibhavs10/incredibly-fast-whisper"

  # @mistral_version ""
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
      HNSWLib.Index.knn_query(index, Nx.tensor(embedding), k: 10)

    labels
    |> Nx.to_flat_list()
    |> Enum.map(fn idx -> Enum.at(chunks, idx) end)
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

  def create_embedding(text) do
    run(@mpnet, @mpnet_version, text: text)
  end

  def create_embeddings(segments) do
    text_batch =
      segments
      |> Enum.map(fn %Library.Segment{body: body} -> body end)
      |> Jason.encode!()

    run(@mpnet, @mpnet_version, text_batch: text_batch)
  end

  def create_embeddings_async(segments) do
    text_batch =
      segments
      |> Enum.map(fn %Library.Segment{body: body} -> body end)
      |> Jason.encode!()

    run_async(@mpnet, @mpnet_version, text_batch: text_batch)
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
    {:ok, tokenizer} =
      Bumblebee.load_tokenizer({:hf, @mistral, auth_token: Algora.config([:hf_token])}, [
        {:type, :llama}
      ])

    tokenizer
  end

  def tokenize_and_measure(%Library.Segment{body: body}, tokenizer) do
    %{"input_ids" => tensor} = Bumblebee.apply_tokenizer(tokenizer, body)
    {1, len} = Nx.shape(tensor)
    len
  end

  def tokenize_and_measure(subtitles, tokenizer) do
    Library.Segment.init(subtitles) |> tokenize_and_measure(tokenizer)
  end

  def format_segment(%Library.Segment{start: start, body: body} = segment),
    do:
      "#{Library.to_hhmmss(start)} - [#{segment.starting_subtitle_id}, #{segment.ending_subtitle_id}]\n#{body}"

  def chunk(video) do
    subtitles = Library.list_subtitles(video)

    chunk(load_tokenizer!(), [], [], subtitles)
    |> Enum.map(&Library.Segment.init/1)
  end

  def chunk(_, chunks, [], []), do: Enum.reverse(chunks)

  def chunk(tokenizer, chunks, chunk, []), do: chunk(tokenizer, [chunk | chunks], [], [])

  # HACK: loops forever when given a word that doesn't fit in a chunk
  # TODO: overlap chunks
  # TODO: ensure each chunk contains content from one speaker only
  def chunk(tokenizer, chunks, chunk, [subtitle | subtitles]) do
    new_chunk = [subtitle | chunk]
    valid? = tokenize_and_measure(new_chunk, tokenizer) <= @chunk_size

    if valid? do
      chunk(tokenizer, chunks, new_chunk, subtitles)
    else
      chunk(
        tokenizer,
        [Enum.reverse(chunk) | chunks],
        chunk |> Enum.take(2),
        [subtitle | subtitles]
      )
    end
  end
end
