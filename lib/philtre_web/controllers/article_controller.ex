defmodule PhiltreWeb.ArticleController do
  use PhiltreWeb, :controller

  alias Philtre.Articles

  def index(conn, _params) do
    articles = Articles.list_articles()
    render(conn, "index.html", articles: articles)
  end

  def show(conn, %{"id" => id}) do
    article = Articles.get_article(id)
    render(conn, "show.html", article: article)
  end
end
