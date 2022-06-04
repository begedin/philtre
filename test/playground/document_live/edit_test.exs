defmodule Playground.DocumentLive.EditTest do
  @moduledoc false

  use Playground.ConnCase

  import Phoenix.LiveViewTest

  alias Philtre.Block.ContentEditable
  alias Philtre.Editor
  alias Playground.Documents

  @editor %Editor{
    id: "-1",
    blocks: [
      %ContentEditable{
        id: "1",
        cells: [%ContentEditable.Cell{id: "1-1", text: "Foo", modifiers: []}],
        type: "h1"
      },
      %ContentEditable{
        id: "2",
        cells: [%ContentEditable.Cell{id: "2-1", text: "Bar", modifiers: []}],
        type: "p"
      },
      %ContentEditable{
        id: "3",
        cells: [%ContentEditable.Cell{id: "3-1", text: "Baz", modifiers: []}],
        type: "p"
      }
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
    _document = Documents.save_document(@editor, "foo")

    {:ok, view, _html} = live(conn, "/documents/foo.json/edit")

    assert dom = view |> render() |> Floki.parse_document!()

    assert dom |> Floki.find("h1[contenteditable]") |> Floki.text() == "Foo"
    assert dom |> Floki.find("p[contenteditable]") |> Floki.text() == "BarBaz"

    assert view |> element("button", "Save") |> render_click()

    assert Documents.get_document("foo") == {:ok, @editor}

    Documents.delete_document("foo")
  end
end
