defmodule Algora.Accounts.Destination do
  use Ecto.Schema
  import Ecto.Changeset

  schema "destinations" do
    field :rtmp_url, :string
    field :stream_key, :string, redact: true
    field :active, :boolean, default: true
    belongs_to :user, Algora.Accounts.User

    timestamps()
  end

  def changeset(destination, attrs) do
    destination
    |> cast(attrs, [:rtmp_url, :stream_key, :active])
    |> validate_required([:rtmp_url, :stream_key])
    |> validate_rtmp_url()
  end

  defp validate_rtmp_url(changeset) do
    validate_change(changeset, :rtmp_url, fn :rtmp_url, rtmp_url ->
      case valid_rtmp_url?(rtmp_url) do
        :ok ->
          []

        {:error, message} ->
          [rtmp_url: message]
      end
    end)
  end

  defp valid_rtmp_url?(url) do
    case URI.parse(url) do
      %URI{scheme: scheme, host: host} when scheme in ["rtmp", "rtmps"] ->
        case :inet.gethostbyname(to_charlist(host)) do
          {:ok, _} -> :ok
          {:error, _} -> {:error, "must have a valid host"}
        end

      _ ->
        {:error, "must be a valid URL starting with rtmp:// or rtmps://"}
    end
  end
end
