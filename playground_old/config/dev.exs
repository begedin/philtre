import Config

config :playground, PlaygroundWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4000],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "cTvdUG+0aK2y3CaXCRKu8UT+bxPRg6l40cnVWp9boYoucVXY4so32JYEr8EWKqLN",
  watchers: [
    # Start the esbuild watcher by calling Esbuild.install_and_run(:default, args)
    node: ["esbuild.js", "--watch", cd: Path.expand("../assets", __DIR__)]
  ],
  live_reload: [
    patterns: [
      ~r"priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"lib/playground_web/(live|views)/.*(ex)$",
      ~r"lib/playground_web/templates/.*(eex)$"
    ]
  ]

config :logger, :console, format: "[$level] $message\n"

config :phoenix, :stacktrace_depth, 20
config :phoenix, :plug_init_mode, :runtime
