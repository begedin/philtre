defmodule PhiltreWeb.DocumentLive.EditTest do
  @moduledoc false

  use PhiltreWeb.ConnCase

  import Phoenix.LiveViewTest

  alias Editor.Block
  alias Philtre.Documents

  @editor %Editor{
    id: "-1",
    blocks: [
      %Block{id: "1", pre_caret: "Foo", type: "h1"},
      %Block{id: "2", pre_caret: "Bar", type: "p"},
      %Block{id: "3", pre_caret: "Baz", type: "p"}
    ]
  }

  test "renders article", %{conn: conn} do
    _document = Documents.save_document(@editor, "foo")

    {:ok, _view, html} = live(conn, "/documents/foo.json/edit")

    dom = Floki.parse_document!(html)

    assert [h1] = Floki.find(dom, "h1[contenteditable]")
    assert Floki.text(h1) == "Foo"

    assert [p_1, p_2] = Floki.find(dom, "p[contenteditable]")
    assert p_1 |> Floki.text() |> String.trim() == "Bar"
    assert p_2 |> Floki.text() |> String.trim() == "Baz"

    Documents.delete_document("foo")
  end

  test "updates and saves article", %{conn: conn} do
    _document = Documents.save_document(%Editor{}, "foo")

    {:ok, view, _html} = live(conn, "/documents/foo.json/edit")

    send(view.pid, {:update, @editor})

    assert dom = view |> render() |> Floki.parse_document!()

    assert dom |> Floki.find("h1[contenteditable]") |> Floki.text() == "Foo"
    assert dom |> Floki.find("p[contenteditable]") |> Floki.text() == "BarBaz"

    assert view |> element("button") |> render_click()

    assert Documents.get_document("foo") == {:ok, @editor}

    Documents.delete_document("foo")
  end
end
