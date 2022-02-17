defmodule Marketplace.RepoCase do
  @moduledoc false
  use ExUnit.CaseTemplate

  using do
    quote do
      alias Marketplace.Repo

      import Ecto
      import Ecto.Query
      import Marketplace.RepoCase
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Marketplace.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Marketplace.Repo, {:shared, self()})
    end

    :ok
  end
end
