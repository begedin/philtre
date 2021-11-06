defmodule PhiltreWeb.ArticleLive.NewTest do
  @moduledoc false

  use PhiltreWeb.ConnCase

  import Phoenix.LiveViewTest

  alias Philtre.Articles
  alias Philtre.Factories

  test "creates article", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/articles/new")

    assert view
           |> form("#article", article: %{title: "Foo", body: "Bar"})
           |> render_submit()

    assert {:ok, %{title: "Foo", body: "Bar"}} = Articles.get_article("foo")
  end

  test "renders preview of article", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/articles/new")

    assert dom =
             view
             |> element("textarea")
             |> render_keyup(%{value: "## Foo"})
             |> Floki.parse_document!()

    assert [h_1] = Floki.find(dom, "h2")
    assert h_1 |> Floki.text() |> String.trim() == "Foo"
  end

  test "validates validation errors", %{conn: conn} do
    article = Factories.create_article()
    {:ok, view, _html} = live(conn, "/articles/new")

    assert view
           |> form("#article", article: %{title: article.title, body: "Bar"})
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
