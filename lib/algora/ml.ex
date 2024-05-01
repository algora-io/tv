defmodule Algora.ML do
  alias Replicate.Predictions
  alias Replicate.Predictions.Prediction
  alias Algora.{Storage, Library}

  @chunk_size 128

  @mistral "mistralai/Mixtral-8x7B-Instruct-v0.1"
  @mpnet "replicate/all-mpnet-base-v2"
  @whisper "vaibhavs10/incredibly-fast-whisper"

  # @mistral_version ""
  @mpnet_version "b6b7585c9640cd7a9572c6e129c9549d79c9c31f0d3fdce7baac7c67ca38f305"
  @whisper_version "3ab86df6c8f54c11309d4d1f930ac292bad43ace52d10c80d87eb258b3c9f79c"

  def get!(id), do: Predictions.get!(id)

  defp index_local_dir(), do: Path.join(System.tmp_dir!(), "algora/hnswlib")
  defp index_local_path(), do: Path.join(index_local_dir(), "index")

  def save_index(index) do
    local_path = index_local_path()
    HNSWLib.Index.save_index(index, local_path)
    Storage.upload_from_filename_to_bucket(local_path, "index", :ml)
  end

  def load_index!() do
    local_path = index_local_path()

    if !File.exists?(local_path) do
      File.mkdir_p!(index_local_dir())

      {:ok, _} =
        ExAws.S3.download_file(Algora.config([:buckets, :ml]), "index", local_path)
        |> ExAws.request()
    end

    load_index_from_disk!(local_path)
  end

  defp load_index_from_disk!(path) do
    case HNSWLib.Index.load_index(:cosine, 768, path, max_elements: 100_000) do
      {:ok, index} ->
        index

      {:error, _} ->
        {:ok, index} = HNSWLib.Index.new(:cosine, 768, 1_000_000)
        save_index(index)
        index
    end
  end

  def add_embeddings(index, segments) do
    for %Library.Segment{id: id, embedding: embedding} <- segments do
      HNSWLib.Index.add_items(index, Nx.tensor(embedding), ids: [id])
    end

    save_index(index)
  end

  def get_relevant_chunks(index, embedding) do
    {:ok, labels, _dist} =
      HNSWLib.Index.knn_query(index, Nx.tensor(embedding), k: 20)

    labels |> Nx.to_flat_list() |> Library.list_segments_by_ids()
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

  def transcribe_video(path) do
    run(
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
    Replicate.run("#{model}:#{version}", input)
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

  def chunk(tokenizer, chunks, chunk, [subtitle | subtitles]) do
    new_chunk = [subtitle | chunk]
    valid? = tokenize_and_measure(new_chunk, tokenizer) <= @chunk_size

    cond do
      valid? ->
        chunk(tokenizer, chunks, new_chunk, subtitles)

      chunk == [] ->
        chunk(
          tokenizer,
          chunks,
          [],
          subtitles
        )

      true ->
        chunk(
          tokenizer,
          [Enum.reverse(chunk) | chunks],
          chunk |> Enum.take(min(2, length(chunk) - 1)),
          [subtitle | subtitles]
        )
    end
  end
end
