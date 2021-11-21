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

    assert [h1] = Floki.find(dom, "h1 span[contenteditable]")
    assert Floki.text(h1) == Articles.Article.title(article)

    assert [p] = Floki.find(dom, "p span[contenteditable]")
    assert p |> Floki.text() |> String.trim() == Articles.Article.body(article)
  end

  test "updates and saves article", %{conn: conn} do
    %{slug: slug} = Factories.create_article()

    {:ok, view, _html} = live(conn, "/articles/#{slug}/edit")

    page = %Editor.Page{
      blocks: [
        %Editor.Block{id: "1", type: "h1", cells: [%Editor.Cell{type: "span", content: "Foo"}]},
        %Editor.Block{id: "2", type: "p", cells: [%Editor.Cell{type: "span", content: "Bar"}]},
        %Editor.Block{id: "3", type: "p", cells: [%Editor.Cell{type: "span", content: "Baz"}]}
      ]
    }

    send(view.pid, {:updated_page, page})

    assert dom = view |> render() |> Floki.parse_document!()

    assert dom |> Floki.find("h1 span[contenteditable]") |> Floki.text() == "Foo"
    assert dom |> Floki.find("p span[contenteditable]") |> Floki.text() == "BarBaz"

    assert view |> element("button") |> render_click()

    assert {:ok, %{content: content}} = Articles.get_article("foo")

    assert content == %{
             "blocks" => [
               %{
                 "cells" => [%{"content" => "Foo", "id" => nil, "type" => "span"}],
                 "id" => "1",
                 "type" => "h1"
               },
               %{
                 "cells" => [%{"content" => "Bar", "id" => nil, "type" => "span"}],
                 "id" => "2",
                 "type" => "p"
               },
               %{
                 "cells" => [%{"content" => "Baz", "id" => nil, "type" => "span"}],
                 "id" => "3",
                 "type" => "p"
               }
             ]
           }
  end

  test "validates validation errors", %{conn: conn} do
    [%{slug: slug}, article_2] = Factories.create_articles(2)

    {:ok, view, _html} = live(conn, "/articles/#{slug}/edit")

    page = %Editor.Page{
      blocks: [
        %Editor.Block{
          id: "1",
          type: "h1",
          cells: [%Editor.Cell{type: "span", content: Articles.Article.title(article_2)}]
        }
      ]
    }

    send(view.pid, {:updated_page, page})

    assert html = view |> element("button") |> render_click()
    assert html =~ "There were some errors"
  end
end
