defmodule Marketplace.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      Marketplace.Repo
      # Starts a worker by calling: Marketplace.Worker.start_link(arg)
      # {Marketplace.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Marketplace.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
