import Config

config :playground, PlaygroundWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "vm8t4RmE0jWnh6P1BbtG5uIlA+5K9pY5sPLu2gOUSNadNvi7DIAEJMzYSlDIPb8/",
  server: false

config :logger, level: :warn

config :phoenix, :plug_init_mode, :runtime
