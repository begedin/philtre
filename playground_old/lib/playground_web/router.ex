defmodule PlaygroundWeb.Router do
  use PlaygroundWeb, :router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:put_root_layout, {PlaygroundWeb.LayoutView, :root})
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  pipeline :api do
    plug(:accepts, ["json"])
  end

  scope "/", PlaygroundWeb do
    pipe_through(:browser)

    live("/documents", DocumentLive.Index, :index)
    live("/documents/new", DocumentLive.New, :new)
    live("/documents/:filename/edit", DocumentLive.Edit, :edit)
    live("/documents/:filename", DocumentLive.Show, :show)

    get("/", DocumentController, :index)
    get("/:filename", DocumentController, :show)
  end
end
