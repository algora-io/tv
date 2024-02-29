import Ecto.Query
import Ecto.Changeset

alias Algora.Accounts
alias Algora.Library
alias Algora.Repo

IEx.configure(inspect: [charlists: :as_lists])

if Code.ensure_loaded?(ExSync) && function_exported?(ExSync, :register_group_leader, 0) do
  ExSync.register_group_leader()
end
