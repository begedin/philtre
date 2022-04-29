defmodule Playground.Engine do
  def setup do
    Logger.configure(level: :debug)

    Application.put_env(:phoenix, :serve_endpoints, true)
    Application.put_env(:phoenix, :json_library, Jason)

    # Configures the endpoint
    Application.put_env(:playground, Playground.Endpoint,
      http: [ip: {127, 0, 0, 1}, port: 4000],
      secret_key_base: "Hu4qQN3iKzTV4fJxhorPQlA/osH9fAMtbtjVS58PFgfw3ja5Z18Q/WSNR9wP4OfW",
      live_view: [signing_salt: "hMegieSe"],
      debug_errors: true,
      check_origin: false,
      code_reloader: true,
      server: true,
      pubsub_server: Playground.PubSub,
      watchers: [
        node: ["esbuild.js", "--watch"]
      ],
      live_reload: [
        patterns: [
          ~r"playground/.*(ex|eex|js|css)$"
        ]
      ]
    )

    Application.ensure_all_started(:os_mon)
  end

  def run do
    Task.async(fn ->
      children = [
        {Phoenix.PubSub, [name: Playground.PubSub, adapter: Phoenix.PubSub.PG2]},
        Playground.Endpoint
      ]

      {:ok, _} = Supervisor.start_link(children, strategy: :one_for_one)
      Process.sleep(:infinity)
    end)
    |> Task.await(:infinity)
  end
end
