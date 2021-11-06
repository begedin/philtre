defmodule PhiltreWeb.ArticleLive.EditTest do
  @moduledoc false

  use PhiltreWeb.ConnCase

  import Phoenix.LiveViewTest

  alias Philtre.Articles
  alias Philtre.Factories

  test "renders article", %{conn: conn} do
    article = Factories.create_article()

    {:ok, _view, html} = live(conn, "/articles/#{article.slug}/edit")

    dom = Floki.parse_document!(html)

    assert [title_input] = Floki.find(dom, "input#article_title")
    assert Floki.attribute(title_input, "value") == [article.title]

    assert [body_input] = Floki.find(dom, "textarea#article_body")
    assert body_input |> Floki.text() |> String.trim() == article.body
  end

  test "updates article", %{conn: conn} do
    article = Factories.create_article()
    {:ok, view, _html} = live(conn, "/articles/#{article.slug}/edit")

    assert view
           |> form("#article", article: %{title: "Foo", body: "Bar"})
           |> render_submit()

    assert {:ok, %{title: "Foo", body: "Bar"}} = Articles.get_article("foo")
  end

  test "renders preview of article", %{conn: conn} do
    article = Factories.create_article()
    {:ok, view, _html} = live(conn, "/articles/#{article.slug}/edit")

    assert dom =
             view
             |> element("textarea")
             |> render_keyup(%{value: "## Foo"})
             |> Floki.parse_document!()

    assert [h_1] = Floki.find(dom, "h2")
    assert h_1 |> Floki.text() |> String.trim() == "Foo"
  end

  test "validates validation errors", %{conn: conn} do
    [article_1, article_2] = Factories.create_articles(2)

    {:ok, view, _html} = live(conn, "/articles/#{article_1.slug}/edit")

    assert view
           |> form("#article", article: %{title: article_2.title, body: "Bar"})
           |> render_submit() =~ "has already been taken"

    assert view
           |> form("#article", article: %{title: "Foo", body: nil})
           |> render_submit()
           |> Floki.parse_document!()
           |> Floki.text() =~ "can't be blank"

    assert view
           |> form("#article", article: %{title: nil, body: "Bar"})
           |> render_submit()
           |> Floki.parse_document!()
           |> Floki.text() =~ "can't be blank"
  end
end
