defmodule PhiltreWeb.ArticleController do
  use PhiltreWeb, :controller

  alias Philtre.Articles
  alias Plug.Conn

  @spec index(Conn.t(), map) :: Conn.t()
  def index(conn, %{}) do
    articles = Articles.list_articles()
    render(conn, "index.html", articles: articles)
  end

  @spec show(Conn.t(), map) :: Conn.t()
  def show(conn, %{"slug" => slug}) do
    case Articles.get_article(slug) do
      {:ok, article} ->
        render(conn, "show.html", article: article)

      {:error, :not_found} ->
        conn
        |> put_view(PhiltreWeb.ErrorView)
        |> put_status(:not_found)
        |> render("404.html")
    end
  end
end
