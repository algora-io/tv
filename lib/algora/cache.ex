defmodule Algora.Cache do
  def refetch(key, f) do
    result = f.()
    key |> path() |> write(result)
    result
  end

  def fetch(key, f) do
    case key |> path() |> read() do
      {:ok, result} -> result
      {:error, _} -> refetch(key, f)
    end
  end

  def path(key) do
    path = key |> String.split("/") |> Enum.map(&Slug.slugify/1)
    Path.join([:code.priv_dir(:algora), "cache"] ++ path)
  end

  defp write(path, content) do
    File.mkdir_p!(Path.dirname(path))
    File.write(path, :erlang.term_to_binary(content))
  end

  defp read(path) do
    case File.read(path) do
      {:ok, binary} -> {:ok, :erlang.binary_to_term(binary)}
      {:error, error} -> {:error, error}
    end
  end
end
