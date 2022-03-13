defmodule PhiltreWeb.ArticleLive.EditTest do
  @moduledoc false

  use PhiltreWeb.ConnCase

  import Phoenix.LiveViewTest

  alias Editor.Block
  alias Philtre.Articles
  alias Philtre.Factories

  @editor %Editor{
    id: "-1",
    blocks: [
      %Block.H1{id: "1", pre_caret: "Foo"},
      %Block.P{id: "2", pre_caret: "Bar"},
      %Block.P{id: "3", pre_caret: "Baz"}
    ]
  }

  test "renders article", %{conn: conn} do
    article = Factories.create_article()

    {:ok, _view, html} = live(conn, "/articles/#{article.slug}/edit")

    dom = Floki.parse_document!(html)

    assert [h1] = Floki.find(dom, "h1[contenteditable]")
    assert Floki.text(h1) == Articles.Article.title(article)

    assert [p] = Floki.find(dom, "p[contenteditable]")
    assert p |> Floki.text() |> String.trim() == Articles.Article.body(article)
  end

  test "updates and saves article", %{conn: conn} do
    %{slug: slug} = Factories.create_article()

    {:ok, view, _html} = live(conn, "/articles/#{slug}/edit")

    send(view.pid, {:update, @editor})

    assert dom = view |> render() |> Floki.parse_document!()

    assert dom |> Floki.find("h1[contenteditable]") |> Floki.text() == "Foo"
    assert dom |> Floki.find("p[contenteditable]") |> Floki.text() == "BarBaz"

    assert view |> element("button") |> render_click()

    assert {:ok, %{content: content}} = Articles.get_article("foo")

    assert content == %{
             "id" => "-1",
             "blocks" => [
               %{"id" => "1", "type" => "h1", "content" => "Foo"},
               %{"id" => "2", "type" => "p", "content" => "Bar"},
               %{"id" => "3", "type" => "p", "content" => "Baz"}
             ]
           }
  end

  test "validates validation errors", %{conn: conn} do
    [%{slug: slug}, article_2] = Factories.create_articles(2)

    {:ok, view, _html} = live(conn, "/articles/#{slug}/edit")

    editor = %Editor{
      id: "-1",
      blocks: [
        %Block.H1{
          id: "1",
          pre_caret: Articles.Article.title(article_2)
        }
      ]
    }

    send(view.pid, {:update, editor})

    assert html = view |> element("button") |> render_click()
    assert html =~ "There were some errors"
  end
end
