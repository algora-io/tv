defmodule Algora.Pipeline.MessageValidator do
  alias Algora.Accounts

  def validate_connect(message) do
    with {:ok, user} <- authenticate_user(message),
         {:ok, user} <- validate_stream_key(user, message) do
      {:ok, user}
    else
      error -> error
    end
  end

  defp validate_stream_key(user, %{stream_key: key}) when is_binary(key) do
    case Accounts.validate_stream_key(user, key) do
      {:ok, user} -> {:ok, user}
      {:error, reason} -> {:error, reason}
    end
  end

  defp validate_stream_key(_user, _message), do: {:error, :missing_stream_key}

  def authenticate_user(%{username: username, password: password}) do
    user = Repo.get_by(User, username: username)

    case user do
      nil ->
        {:error, :invalid_credentials}

      _ ->
        case Bcrypt.verify_pass(password, user.password_hash) do
          true ->
            {:ok, user}

          false ->
            {:error, :invalid_credentials}
        end
    end
  end

  def authenticate_user(_), do: {:error, :invalid_credentials}
end
