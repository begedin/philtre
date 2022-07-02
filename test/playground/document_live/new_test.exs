defmodule Playground.DocumentLive.NewTest do
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
        kind: "h1"
      },
      %ContentEditable{
        id: "2",
        cells: [%ContentEditable.Cell{id: "2-1", text: "Bar", modifiers: []}],
        kind: "p"
      },
      %ContentEditable{
        id: "3",
        cells: [%ContentEditable.Cell{id: "3-1", text: "Baz", modifiers: []}],
        kind: "p"
      }
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
               %ContentEditable{
                 id: "1",
                 cells: [%{id: "1-1", text: "Foo", modifiers: []}],
                 kind: "h1"
               },
               %ContentEditable{
                 id: "2",
                 cells: [%{id: "2-1", text: "Bar", modifiers: []}],
                 kind: "p"
               },
               %ContentEditable{
                 id: "3",
                 cells: [%{id: "3-1", text: "Baz", modifiers: []}],
                 kind: "p"
               }
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
             %ContentEditable{cells: [%{text: "Foo"}], kind: "h1"},
             %ContentEditable{cells: [%{text: "Bar"}], kind: "p"}
           ] = editor.clipboard

    block = Enum.at(@editor.blocks, 0)

    view
    |> element("[id^=#{block.id}]")
    |> render_hook("paste_blocks", %{
      "selection" => %{
        "start_id" => "1-1",
        "end_id" => "1-1",
        "start_offset" => 1,
        "end_offset" => 1
      }
    })

    assert %{socket: %{assigns: %{editor: %Editor{} = editor}}} = :sys.get_state(view.pid)
    assert Enum.count(editor.blocks) == 6
    assert Editor.text(editor) == "FFooBarooBarBaz"
  end

  test "can save a code block with javascript", %{conn: conn} do
    {:ok, view, html} = live(conn, "/documents/new")

    {"p", p_attrs, [cell]} =
      html
      |> Floki.parse_document!()
      |> Floki.find(".philtre-block")
      |> Enum.at(-1)

    block_id = p_attrs |> Map.new() |> Map.get("id")
    {"span", cell_attrs, _content} = cell
    cell_id = cell_attrs |> Map.new() |> Map.get("data-cell-id")

    view
    |> element(".philtre-block[id=#{block_id}")
    |> render_hook("update", %{
      "selection" => %{
        "start_id" => cell_id,
        "end_id" => cell_id,
        "start_offset" => 5,
        "end_offset" => 5
      },
      "cells" => [
        %{
          "id" => cell_id,
          "modifiers" => [],
          "text" => "/code"
        }
      ]
    })

    view |> element(".philtre__code form") |> render_change(%{"language" => "javascript"})

    filename = UUID.uuid4()

    assert view
           |> element("form[phx-submit=save]")
           |> render_submit(%{"filename" => filename})

    assert content =
             File.cwd!()
             |> Path.join("playground/priv/documents")
             |> Path.join("#{filename}.json")
             |> File.read!()
             |> Jason.decode!()

    assert %{
             "blocks" => [
               %{"type" => "contenteditable", "data" => %{"kind" => "h1"}},
               %{"type" => "code", "data" => %{"language" => "javascript"}}
             ]
           } = content
  end
end
