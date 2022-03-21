import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :philtre, PhiltreWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "vm8t4RmE0jWnh6P1BbtG5uIlA+5K9pY5sPLu2gOUSNadNvi7DIAEJMzYSlDIPb8/",
  server: false

# In test we don't send emails.
config :philtre, Philtre.Mailer, adapter: Swoosh.Adapters.Test

# Print only warnings and errors during test
config :logger, level: :warn

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
