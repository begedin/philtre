defmodule Playground.Endpoint do
  use Phoenix.Endpoint, otp_app: :philtre

  socket("/live", Phoenix.LiveView.Socket)

  plug(Plug.Static,
    at: "/",
    from: "playground/priv/static",
    gzip: false,
    only: ~w(app.css app.js)
  )

  if code_reloading? do
    socket("/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket)
    plug(Phoenix.LiveReloader)
    plug(Phoenix.CodeReloader)
  end

  plug(Plug.Session,
    store: :cookie,
    key: "_live_view_key",
    signing_salt: "/VEDsdfsffMnp5"
  )

  plug(Plug.RequestId)
  plug(Playground.Router)
end
