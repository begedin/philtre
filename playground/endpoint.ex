defmodule Playground.Endpoint do
  use Phoenix.Endpoint, otp_app: :playground

  socket("/live", Phoenix.LiveView.Socket)
  socket("/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket)

  plug(Plug.Static,
    at: "/",
    from: "playground/priv/static",
    gzip: false,
    only: ~w(app.css app.js)
  )

  plug(Phoenix.LiveReloader)
  plug(Phoenix.CodeReloader)

  plug(Plug.Session,
    store: :cookie,
    key: "_live_view_key",
    signing_salt: "/VEDsdfsffMnp5"
  )

  plug(Plug.RequestId)
  plug(Playground.Router)
end
