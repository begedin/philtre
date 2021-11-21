defmodule PhiltreWeb.ArticleLive.IndexTest do
  @moduledoc false

  use PhiltreWeb.ConnCase

  import Phoenix.LiveViewTest

  alias Philtre.Articles
  alias Philtre.Factories

  test "renders articles", %{conn: conn} do
    [article_1, article_2] = Factories.create_articles(2)

    {:ok, _view, html} = live(conn, "/articles")

    dom = Floki.parse_document!(html)

    assert Floki.text(dom) =~ Articles.Article.title(article_1)
    assert Floki.text(dom) =~ Articles.Article.title(article_2)
  end
end
