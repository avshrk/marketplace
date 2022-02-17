defmodule Marketplace.Repo do
  @moduledoc """

  Marketplace Repo Module
  """
  use Ecto.Repo,
    otp_app: :marketplace,
    adapter: Ecto.Adapters.Postgres
end
