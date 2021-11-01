defmodule PhiltreWeb.ArticleController do
  use PhiltreWeb, :controller

  alias Philtre.Articles

  def index(conn, %{}) do
    articles = Articles.list_articles()
    render(conn, "index.html", articles: articles)
  end

  def show(conn, %{"slug" => slug}) do
    with {:ok, article} <- Articles.get_article(slug) do
      render(conn, "show.html", article: article)
    else
      {:error, :not_found} ->
        conn
        |> put_view(PhiltreWeb.ErrorView)
        |> put_status(:not_found)
        |> render("404.html")
    end
  end
end
