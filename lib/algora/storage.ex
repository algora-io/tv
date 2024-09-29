defmodule Algora.Storage do
  def endpoint_url do
    %{scheme: scheme, host: host} = Application.fetch_env!(:ex_aws, :s3) |> Enum.into(%{})
    "#{scheme}#{host}"
  end

  def bucket(), do: Algora.config([:buckets, :media])

  def to_absolute(type, uuid, uri) do
    if URI.parse(uri).scheme do
      uri
    else
      to_absolute_uri(type, uuid, uri)
    end
  end

  defp to_absolute_uri(:video, uuid, uri),
    do: "#{endpoint_url()}/#{bucket()}/#{uuid}/#{uri}"

  defp to_absolute_uri(:clip, uuid, uri),
    do: "#{endpoint_url()}/#{bucket()}/clips/#{uuid}/#{uri}"

  def upload_to_bucket(contents, remote_path, bucket, opts \\ []) do
    op = Algora.config([:buckets, bucket]) |> ExAws.S3.put_object(remote_path, contents, opts)
    ExAws.request(op, [])
  end

  def upload_from_filename_to_bucket(
        local_path,
        remote_path,
        bucket,
        cb \\ fn _ -> nil end,
        opts \\ []
      ) do
    %{size: size} = File.stat!(local_path)

    chunk_size = 5 * 1024 * 1024

    ExAws.S3.Upload.stream_file(local_path, [{:chunk_size, chunk_size}])
    |> Stream.map(fn chunk ->
      cb.(%{stage: :persisting, done: chunk_size, total: size})
      chunk
    end)
    |> ExAws.S3.upload(Algora.config([:buckets, bucket]), remote_path, opts)
    |> ExAws.request([])
  end

  def upload(contents, remote_path, opts \\ []) do
    upload_to_bucket(contents, remote_path, :media, opts)
  end

  def upload_from_filename(local_path, remote_path, cb \\ fn _ -> nil end, opts \\ []) do
    upload_from_filename_to_bucket(
      local_path,
      remote_path,
      :media,
      cb,
      opts
    )
  end

  def update_object!(bucket, object, opts) do
    bucket = Algora.config([:buckets, bucket])

    with {:ok, %{body: body}} <- ExAws.S3.get_object(bucket, object) |> ExAws.request(),
         {:ok, res} <- ExAws.S3.put_object(bucket, object, body, opts) |> ExAws.request() do
      res
    else
      err -> err
    end
  end
end
