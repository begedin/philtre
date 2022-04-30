import Config

config :phoenix, :json_library, Jason
config :logger, :level, :warn

config :philtre, Playground.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4000],
  secret_key_base: "Hu4qQN3iKzTV4fJxhorPQlA/osH9fAMtbtjVS58PFgfw3ja5Z18Q/WSNR9wP4OfW",
  live_view: [signing_salt: "hMegieSe"],
  debug_errors: true,
  check_origin: false,
  code_reloader: false,
  render_errors: [view: Playground.View, accepts: ~w(html)],
  server: false,
  pubsub_server: Playground.PubSub
