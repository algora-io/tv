defmodule Algora.Ads do
  @moduledoc """
  The Ads context.
  """

  import Ecto.Query, warn: false
  alias Algora.Repo

  alias Algora.Ads.{Ad, Visit, Impression}

  @doc """
  Returns the list of ads.

  ## Examples

      iex> list_ads()
      [%Ad{}, ...]

  """
  def list_ads do
    Repo.all(Ad)
  end

  @doc """
  Gets a single ad.

  Raises `Ecto.NoResultsError` if the Ad does not exist.

  ## Examples

      iex> get_ad!(123)
      %Ad{}

      iex> get_ad!(456)
      ** (Ecto.NoResultsError)

  """
  def get_ad!(id), do: Repo.get!(Ad, id)

  def get_ad_by_slug!(slug) do
    Repo.get_by!(Ad, slug: slug)
  end

  @doc """
  Creates a ad.

  ## Examples

      iex> create_ad(%{field: value})
      {:ok, %Ad{}}

      iex> create_ad(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_ad(attrs \\ %{}) do
    %Ad{}
    |> Ad.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a ad.

  ## Examples

      iex> update_ad(ad, %{field: new_value})
      {:ok, %Ad{}}

      iex> update_ad(ad, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_ad(%Ad{} = ad, attrs) do
    ad
    |> Ad.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a ad.

  ## Examples

      iex> delete_ad(ad)
      {:ok, %Ad{}}

      iex> delete_ad(ad)
      {:error, %Ecto.Changeset{}}

  """
  def delete_ad(%Ad{} = ad) do
    Repo.delete(ad)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking ad changes.

  ## Examples

      iex> change_ad(ad)
      %Ecto.Changeset{data: %Ad{}}

  """
  def change_ad(%Ad{} = ad, attrs \\ %{}) do
    Ad.changeset(ad, attrs)
  end

  def track_visit(attrs \\ %{}) do
    %Visit{}
    |> Visit.changeset(attrs)
    |> Repo.insert()
  end

  def track_impressions(attrs \\ %{}) do
    %Impression{}
    |> Impression.changeset(attrs)
    |> Repo.insert()
  end

  def next_ad_slot(time \\ DateTime.utc_now()) do
    time
    |> DateTime.truncate(:second)
    |> DateTime.add(600 - rem(time.minute * 60 + time.second, 600), :second)
  end

  def time_until_next_ad_slot(time \\ DateTime.utc_now()) do
    next_ad_slot(time)
    |> DateTime.diff(time, :millisecond)
  end
end
