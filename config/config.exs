import Config

config :marketplace, Marketplace.Repo,
  database: "marketplace_repo",
  username: "postgres",
  password: "postgres",
  hostname: "localhost"

config :marketplace,
  ecto_repos: [Marketplace.Repo],
  migration_timestamps: [type: :utc_datetime_usec]

import_config "#{Mix.env()}.exs"
