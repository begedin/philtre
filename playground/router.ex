defmodule Playground.Router do
  use Phoenix.Router

  import Plug.Conn
  import Phoenix.Controller
  import Phoenix.LiveView.Router

  pipeline :browser do
    plug(:put_root_layout, {Playground.View, :root})
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
