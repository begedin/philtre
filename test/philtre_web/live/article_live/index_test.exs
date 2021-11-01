defmodule PhiltreWeb.ArticleLive.IndexTest do
  @moduledoc false

  use PhiltreWeb.ConnCase

  import Phoenix.LiveViewTest

  alias Philtre.Factories

  test "renders articles", %{conn: conn} do
    [article_1, article_2] = Factories.create_articles(2)

    {:ok, _view, html} = live(conn, "/articles")

    dom = Floki.parse_document!(html)
    assert Floki.text(dom) =~ article_1.title
    assert Floki.text(dom) =~ article_2.title
  end
end
