defmodule AlgoraWeb.OAuthCallbackController do
  use AlgoraWeb, :controller
  require Logger

  alias Algora.Accounts

  def new(conn, %{"provider" => "github", "code" => code, "state" => state} = params) do
    client = github_client(conn)

    with {:ok, info} <- client.exchange_access_token(code: code, state: state),
         %{info: info, primary_email: primary, emails: emails, token: token} = info,
         {:ok, user} <- Accounts.register_github_user(primary, info, emails, token) do
      conn =
        if params["return_to"] do
          conn |> put_session(:user_return_to, params["return_to"])
        else
          conn
        end

      conn
      |> put_flash(:info, "Welcome, #{user.handle}!")
      |> AlgoraWeb.UserAuth.log_in_user(user)
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        Logger.debug("failed GitHub insert #{inspect(changeset.errors)}")

        conn
        |> put_flash(
          :error,
          "We were unable to fetch the necessary information from your GithHub account"
        )
        |> redirect(to: "/")

      {:error, reason} ->
        Logger.debug("failed GitHub exchange #{inspect(reason)}")

        conn
        |> put_flash(:error, "We were unable to contact GitHub. Please try again later")
        |> redirect(to: "/")
    end
  end

  def new(conn, %{"provider" => "github", "error" => "access_denied"}) do
    redirect(conn, to: "/")
  end

  def new(conn, %{"provider" => "restream", "code" => code, "state" => state, "scope" => scope}) do
    client = restream_client(conn)

    with {:ok, tokens} <- client.exchange_access_token(code: code, state: state),
         {:ok, user} <- Accounts.register_restream_user(tokens) do
      conn
      |> put_flash(:info, "Welcome, #{user.handle}!")
      |> AlgoraWeb.UserAuth.log_in_user(user)
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        Logger.debug("failed Restream insert #{inspect(changeset.errors)}")

        conn
        |> put_flash(:error, "We were unable to fetch the necessary information from your Restream account")
        |> redirect(to: "/")

      {:error, reason} ->
        Logger.debug("failed Restream exchange #{inspect(reason)}")

        conn
        |> put_flash(:error, "We were unable to contact Restream. Please try again later")
        |> redirect(to: "/")
    end
  end

  def sign_out(conn, _) do
    AlgoraWeb.UserAuth.log_out_user(conn)
  end

  defp github_client(conn) do
    conn.assigns[:github_client] || Algora.Github
  end

  defp restream_client(conn) do
    conn.assigns[:restream_client] || Algora.Restream
  end
end
