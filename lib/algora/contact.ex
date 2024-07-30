defmodule Algora.Contact do
  @moduledoc """
  The Contact context.
  """

  import Ecto.Query, warn: false
  alias Algora.Repo

  alias Algora.Contact.Info

  @doc """
  Returns the list of contact_info.

  ## Examples

      iex> list_contact_info()
      [%Info{}, ...]

  """
  def list_contact_info do
    Repo.all(Info)
  end

  @doc """
  Gets a single info.

  Raises `Ecto.NoResultsError` if the Info does not exist.

  ## Examples

      iex> get_info!(123)
      %Info{}

      iex> get_info!(456)
      ** (Ecto.NoResultsError)

  """
  def get_info!(id), do: Repo.get!(Info, id)

  @doc """
  Creates a info.

  ## Examples

      iex> create_info(%{field: value})
      {:ok, %Info{}}

      iex> create_info(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_info(attrs \\ %{}) do
    %Info{}
    |> Info.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a info.

  ## Examples

      iex> update_info(info, %{field: new_value})
      {:ok, %Info{}}

      iex> update_info(info, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_info(%Info{} = info, attrs) do
    info
    |> Info.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a info.

  ## Examples

      iex> delete_info(info)
      {:ok, %Info{}}

      iex> delete_info(info)
      {:error, %Ecto.Changeset{}}

  """
  def delete_info(%Info{} = info) do
    Repo.delete(info)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking info changes.

  ## Examples

      iex> change_info(info)
      %Ecto.Changeset{data: %Info{}}

  """
  def change_info(%Info{} = info, attrs \\ %{}) do
    Info.changeset(info, attrs)
  end
end
