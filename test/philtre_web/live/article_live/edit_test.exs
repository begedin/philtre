defmodule PhiltreWeb.ArticleLive.EditTest do
  @moduledoc false

  use PhiltreWeb.ConnCase

  import Phoenix.LiveViewTest

  alias Philtre.Articles
  alias Philtre.Factories

  test "renders article", %{conn: conn} do
    %{
      sections: [%{content: title}, %{content: body}],
      slug: slug
    } = Factories.create_article()

    {:ok, _view, html} = live(conn, "/articles/#{slug}/edit")

    dom = Floki.parse_document!(html)

    assert [h1] = Floki.find(dom, "h1[contenteditable]")
    assert Floki.text(h1) == title

    assert [p] = Floki.find(dom, "p[contenteditable]")
    assert p |> Floki.text() |> String.trim() == body
  end

  test "updates and saves article", %{conn: conn} do
    %{slug: slug} = Factories.create_article()

    {:ok, view, _html} = live(conn, "/articles/#{slug}/edit")

    page = %Editor.Page{
      blocks: [
        %Editor.Block{id: "1", type: "h1", content: "Foo"},
        %Editor.Block{id: "2", type: "p", content: "Bar"},
        %Editor.Block{id: "3", type: "p", content: "Baz"}
      ]
    }

    send(view.pid, {:updated_page, page})

    assert dom = view |> render() |> Floki.parse_document!()

    assert dom |> Floki.find("h1[contenteditable]") |> Floki.text() == "Foo"
    assert dom |> Floki.find("p[contenteditable]") |> Floki.text() == "BarBaz"

    assert view |> element("button") |> render_click()

    assert {:ok,
            %{
              sections: [
                %Philtre.Articles.Article.Section{content: "Foo", id: "1", type: "h1"},
                %Philtre.Articles.Article.Section{content: "Bar", id: "2", type: "p"},
                %Philtre.Articles.Article.Section{content: "Baz", id: "3", type: "p"}
              ]
            }} = Articles.get_article("foo")
  end

  test "validates validation errors", %{conn: conn} do
    [%{slug: slug}, %{sections: [title_section_2 | _]}] = Factories.create_articles(2)

    {:ok, view, _html} = live(conn, "/articles/#{slug}/edit")

    page = %Editor.Page{
      blocks: [
        %Editor.Block{id: "1", type: "h1", content: title_section_2.content}
      ]
    }

    send(view.pid, {:updated_page, page})

    assert html = view |> element("button") |> render_click()
    assert html =~ "There were some errors"
  end
end
