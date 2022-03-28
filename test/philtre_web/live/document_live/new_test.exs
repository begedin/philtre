defmodule PhiltreWeb.DocumentLive.NewTest do
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

  test "creates document", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/documents/new")

    send(view.pid, {:update, @editor})

    assert dom = view |> render() |> Floki.parse_document!()

    assert dom |> Floki.find("h1[contenteditable]") |> Floki.text() == "Foo"
    assert dom |> Floki.find("p[contenteditable]") |> Floki.text() == "BarBaz"

    assert view |> element("form") |> render_submit(%{"filename" => "foo"})

    assert {:ok, %Editor{} = editor} = Documents.get_document("foo")

    assert %Editor{
             blocks: [
               %Editor.Block{post_caret: "", pre_caret: "Foo", type: "h1"},
               %Editor.Block{post_caret: "", pre_caret: "Bar", type: "p"},
               %Editor.Block{post_caret: "", pre_caret: "Baz", type: "p"}
             ],
             clipboard: nil,
             selected_blocks: [],
             selection: nil
           } = editor

    Documents.delete_document("foo")
  end

  test "can select,then copy and paste blocks", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/documents/new")

    send(view.pid, {:update, @editor})

    block_ids = @editor.blocks |> Enum.map(& &1.id) |> Enum.take(2)

    view
    |> element("[id=editor__selection__#{@editor.id}]")
    |> render_hook("select_blocks", %{"block_ids" => block_ids})

    assert %{socket: %{assigns: %{editor: %Editor{} = editor}}} = :sys.get_state(view.pid)
    assert editor.selected_blocks == block_ids

    view
    |> element("[id=editor__selection__#{@editor.id}]")
    |> render_hook("copy_blocks", %{"block_ids" => block_ids})

    assert %{socket: %{assigns: %{editor: %Editor{} = editor}}} = :sys.get_state(view.pid)

    assert [
             %Editor.Block{post_caret: "", pre_caret: "Foo", type: "h1"},
             %Editor.Block{post_caret: "", pre_caret: "Bar", type: "p"}
           ] = editor.clipboard

    block = Enum.at(@editor.blocks, 0)

    view
    |> element("[id^=#{block.id}]")
    |> render_hook("paste_blocks", %{"pre" => "Fo", "post" => "o"})

    assert %{socket: %{assigns: %{editor: %Editor{} = editor}}} = :sys.get_state(view.pid)
    assert Enum.count(editor.blocks) == 6
    assert Editor.text(editor) == "FoFooBaroBarBaz"
  end
end
