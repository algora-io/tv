defmodule Algora.Shows do
  import Ecto.Query, warn: false
  alias Algora.Repo

  alias Algora.Shows.Show
  alias Algora.Accounts.User

  def list_shows(limit \\ 100) do
    from(s in Show,
      join: u in User,
      on: s.user_id == u.id,
      limit: ^limit,
      select_merge: %{
        channel_handle: u.handle,
        channel_name: coalesce(u.name, u.handle),
        channel_avatar_url: u.avatar_url,
        channel_twitter_url: u.twitter_url
      },
      order_by: [{:desc, s.updated_at}, {:desc, s.id}]
    )
    |> Repo.all()
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

  def list_videos do
    Repo.all(Show)
  end
end
