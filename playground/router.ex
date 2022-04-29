defmodule Playground.Router do
  use Phoenix.Router

  import Plug.Conn
  import Phoenix.Controller
  import Phoenix.LiveView.Router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:put_root_layout, {Playground.View, :root})
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  pipeline :api do
    plug(:accepts, ["json"])
  end

  scope "/", Playground do
    pipe_through(:browser)

    live("/documents", Live.Index)
    live("/documents/new", Live.New)
    live("/documents/:filename/edit", Live.Edit)
    live("/documents/:filename", Live.Show)

    get("/", Controller, :index)
    get("/:filename", Controller, :show)
  end
end
