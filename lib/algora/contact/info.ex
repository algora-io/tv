defmodule Algora.Contact.Info do
  use Ecto.Schema
  import Ecto.Changeset

  schema "contact_info" do
    field :email, :string
    field :website_url, :string
    field :revenue, :string
    field :company_location, :string

    timestamps()
  end

  @doc false
  def changeset(info, attrs) do
    info
    |> cast(attrs, [:email, :website_url, :revenue, :company_location])
    |> validate_required([:email])
  end
end
