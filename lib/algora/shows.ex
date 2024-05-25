defmodule Algora.Shows do
  import Ecto.Query, warn: false
  alias Algora.Repo

  alias Algora.Shows.Show

  def list_shows do
    Repo.all(Show)
  end

  def get_show!(id), do: Repo.get!(Show, id)

  def get_show_by_fields!(fields), do: Repo.get_by!(Show, fields)

  def create_show(attrs \\ %{}) do
    %Show{}
    |> Show.changeset(attrs)
    |> Repo.insert()
  end

  def update_show(%Show{} = show, attrs) do
    show
    |> Show.changeset(attrs)
    |> Repo.update()
  end

  def delete_show(%Show{} = show) do
    Repo.delete(show)
  end

  def change_show(%Show{} = show, attrs \\ %{}) do
    Show.changeset(show, attrs)
  end
end
