defmodule PhiltreWeb.PageController do
  use PhiltreWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
