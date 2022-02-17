import Config

config :marketplace, Marketplace.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "marketplace_dev",
  show_sensitive_data_on_connection_error: true,
  pool_size: 10
