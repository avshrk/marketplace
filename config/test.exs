import Config

config :marketplace, Marketplace.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "marketplace_test",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10,
  log: :false
