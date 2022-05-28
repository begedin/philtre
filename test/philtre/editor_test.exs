defmodule Philtre.EditorTest do
  @moduledoc false

  use Philtre.EditorCase

  import Phoenix.LiveViewTest

  alias Philtre.Editor
  alias Philtre.Editor.Block

  @editor %Editor{
    id: "-5",
    blocks: [
      %Block{id: "1", cells: [%Block.Cell{id: "1-1", text: "Foo", modifiers: []}], type: "h1"},
      %Block{id: "2", cells: [%Block.Cell{id: "2-1", text: "Bar", modifiers: []}], type: "p"},
      %Block{id: "3", cells: [%Block.Cell{id: "3-1", text: "Baz", modifiers: []}], type: "p"}
    ]
  }

  test "can select,then copy and paste in the middle of a block", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, Wrapper)

    Wrapper.set_editor(view, @editor)

    block_ids = @editor.blocks |> Enum.map(& &1.id) |> Enum.take(2)

    Wrapper.select_blocks(view, block_ids)

    editor = Wrapper.get_editor(view)
    assert editor.selected_blocks == block_ids

    Wrapper.copy_blocks(view, block_ids)

    editor = Wrapper.get_editor(view)

    assert [
             %Block{id: _, cells: [%{id: "1-1", text: "Foo", modifiers: []}], type: "h1"},
             %Block{id: _, cells: [%{id: "2-1", text: "Bar", modifiers: []}], type: "p"}
           ] = editor.clipboard

    # pasting right after first "Foo"
    Wrapper.paste_blocks(view, 0, %{
      selection: %{start_id: "1-1", end_id: "1-1", start_offset: 2, end_offset: 2}
    })

    editor = Wrapper.get_editor(view)
    assert Enum.count(editor.blocks) == 6

    assert %{
             blocks: [
               %Block{cells: [%{text: "Fo"}], type: "h1"},
               %Block{cells: [%{text: "Foo"}], type: "h1"},
               %Block{cells: [%{text: "Bar"}], type: "p"},
               %Block{cells: [%{text: "o"}], type: "h1"},
               %Block{cells: [%{text: "Bar"}], type: "p"},
               %Block{cells: [%{text: "Baz"}], type: "p"}
             ]
           } = editor
  end

  test "can select,then copy and paste blocks at the end of a block", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, Wrapper)

    Wrapper.set_editor(view, @editor)

    block_ids = @editor.blocks |> Enum.map(& &1.id) |> Enum.take(2)

    Wrapper.select_blocks(view, block_ids)

    editor = Wrapper.get_editor(view)
    assert editor.selected_blocks == block_ids

    Wrapper.copy_blocks(view, block_ids)

    editor = Wrapper.get_editor(view)

    assert [
             %Block{cells: [%{text: "Foo"}], type: "h1"},
             %Block{cells: [%{text: "Bar"}], type: "p"}
           ] = editor.clipboard

    %{cells: [cell]} = block = Wrapper.block_at(view, 0)
    # pasting right after first "Foo"
    Wrapper.paste_blocks(view, block, %{
      selection: %{start_id: cell.id, end_id: cell.id, start_offset: 3, end_offset: 3}
    })

    editor = Wrapper.get_editor(view)

    assert %{
             blocks: [
               %Block{cells: [%{text: "Foo"}], type: "h1"},
               %Block{cells: [%{text: "Foo"}], type: "h1"},
               %Block{cells: [%{text: "Bar"}], type: "p"},
               %Block{cells: [%{text: "Bar"}], type: "p"},
               %Block{cells: [%{text: "Baz"}], type: "p"}
             ]
           } = editor
  end

  test "can insert block after block", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, Wrapper)

    Wrapper.set_editor(view, Editor.new())
    Wrapper.trigger_split_block(view, Wrapper.block_at(view, 0), :end)
    assert %Block{cells: [%{text: " "}], type: "p"} = Wrapper.block_at(view, 1)
  end

  test "can convert block to h1", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, Wrapper)

    %Block{type: "h1"} = h1 = Wrapper.block_at(view, 0)
    Wrapper.trigger_split_block(view, h1, :end)

    %Block{type: "p"} = p = Wrapper.block_at(view, 1)
    assert %{cells: [%{text: " "} = cell]} = p

    Wrapper.trigger_update(view, p, %{
      cells: [cell |> Map.from_struct() |> Map.put(:text, "# ")],
      selection: %{start_id: cell.id, end_id: cell.id, start_offset: 2, end_offset: 2}
    })

    assert %Block{type: "h1"} = h1 = Wrapper.block_at(view, 1)
    assert %{cells: [%{text: ""}]} = h1
  end

  test "can convert block to h2", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, Wrapper)

    %Block{type: "h1"} = h1 = Wrapper.block_at(view, 0)
    Wrapper.trigger_split_block(view, h1, :end)

    %Block{type: "p"} = p = Wrapper.block_at(view, 1)
    assert %{cells: [%{text: " "} = cell]} = p

    Wrapper.trigger_update(view, p, %{
      cells: [cell |> Map.from_struct() |> Map.put(:text, "## ")],
      selection: %{start_id: cell.id, end_id: cell.id, start_offset: 3, end_offset: 3}
    })

    assert %Block{type: "h2"} = h2 = Wrapper.block_at(view, 1)
    assert %{cells: [%{text: ""}]} = h2
  end

  test "can convert block to h3", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, Wrapper)

    %Block{type: "h1"} = h1 = Wrapper.block_at(view, 0)
    Wrapper.trigger_split_block(view, h1, :end)

    %Block{type: "p"} = p = Wrapper.block_at(view, 1)
    assert %{cells: [%{text: " "} = cell]} = p

    Wrapper.trigger_update(view, p, %{
      cells: [cell |> Map.from_struct() |> Map.put(:text, "### ")],
      selection: %{start_id: cell.id, end_id: cell.id, start_offset: 4, end_offset: 4}
    })

    assert %Block{type: "h3"} = h3 = Wrapper.block_at(view, 1)
    assert %{cells: [%{text: ""}]} = h3
  end

  test "can convert block to pre", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, Wrapper)

    %Block{type: "h1"} = h1 = Wrapper.block_at(view, 0)
    Wrapper.trigger_split_block(view, h1, :end)

    %Block{type: "p"} = p = Wrapper.block_at(view, 1)
    assert %{cells: [%{text: " "} = cell]} = p

    Wrapper.trigger_update(view, p, %{
      cells: [cell |> Map.from_struct() |> Map.put(:text, "```")],
      selection: %{start_id: cell.id, end_id: cell.id, start_offset: 3, end_offset: 3}
    })

    assert %Block{type: "pre"} = pre = Wrapper.block_at(view, 1)
    assert %{cells: [%{text: ""}]} = pre
  end

  test "can convert block to li", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, Wrapper)

    %Block{type: "h1"} = h1 = Wrapper.block_at(view, 0)
    Wrapper.trigger_split_block(view, h1, :end)

    %Block{type: "p"} = p = Wrapper.block_at(view, 1)
    assert %{cells: [%{text: " "} = cell]} = p

    Wrapper.trigger_update(view, p, %{
      cells: [cell |> Map.from_struct() |> Map.put(:text, "* foo")],
      selection:
        Map.from_struct(%Block.Selection{
          start_id: cell.id,
          end_id: cell.id,
          start_offset: 4,
          end_offset: 4
        })
    })

    assert %Block{type: "li"} = li = Wrapper.block_at(view, 1)
    assert %{cells: [%{text: "foo"}]} = li
  end

  test "can downgrade h1 to h2 to h3 to p", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, Wrapper)
    assert %Block{type: "h1"} = Wrapper.block_at(view, 0)

    Wrapper.trigger_backspace_from_start(view, 0)
    assert %Block{type: "h2"} = Wrapper.block_at(view, 0)

    Wrapper.trigger_backspace_from_start(view, 0)
    assert %Block{type: "h3"} = Wrapper.block_at(view, 0)

    Wrapper.trigger_backspace_from_start(view, 0)
    assert %Block{type: "p"} = Wrapper.block_at(view, 0)
  end

  test "can downgrade li to p, merging cells", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, Wrapper)
    %Block{cells: [cell]} = block = Wrapper.block_at(view, 1)

    Wrapper.trigger_update(view, block, %{
      cells: [cell |> Map.from_struct() |> Map.put(:text, "* fooo")],
      selection: %{start_id: cell.id, end_id: cell.id, start_offset: 4, end_offset: 4}
    })

    assert %Block{type: "li"} = Wrapper.block_at(view, 1)

    Wrapper.trigger_backspace_from_start(view, 1)
    assert %Block{type: "p"} = Wrapper.block_at(view, 1)
  end

  test "can downgrade pre to p", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, Wrapper)

    %{cells: [cell]} = block = Wrapper.block_at(view, 1)

    Wrapper.trigger_update(view, block, %{
      cells: [cell |> Map.from_struct() |> Map.put(:text, "```")],
      selection: %{start_id: cell.id, end_id: cell.id, start_offset: 3, end_offset: 3}
    })

    assert %Block{type: "pre"} = Wrapper.block_at(view, 1)

    Wrapper.trigger_backspace_from_start(view, 1)
    assert %Block{type: "p"} = Wrapper.block_at(view, 1)
  end

  test "can merge multiple p blocks", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, Wrapper)

    %{blocks: [block, _]} = Wrapper.get_editor(view)
    %{cells: [cell]} = block

    Wrapper.trigger_split_block(view, block, %{
      selection: %{start_id: cell.id, end_id: cell.id, start_offset: 4, end_offset: 4}
    })

    %{blocks: [_, block, _]} = Wrapper.get_editor(view)
    %{cells: [cell]} = block

    Wrapper.trigger_split_block(view, block, %{
      selection: %{start_id: cell.id, end_id: cell.id, start_offset: 4, end_offset: 4}
    })

    assert %{
             blocks: [%Block{type: "h1"}, %Block{type: "p"}, %Block{type: "p"}, %Block{type: "p"}]
           } = Wrapper.get_editor(view)

    Wrapper.trigger_backspace_from_start(view, 3)
    Wrapper.trigger_backspace_from_start(view, 2)
    Wrapper.trigger_backspace_from_start(view, 1)

    assert %{blocks: [%Block{type: "h1", cells: [_, _, _, _] = cells}]} = Wrapper.get_editor(view)

    assert [
             %{text: "This"},
             %{text: " is "},
             %{text: "the title of your page"},
             %{text: "This is your first paragraph."}
           ] = cells
  end

  test "can undo and redo", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, Wrapper)

    %{blocks: [block, _]} = Wrapper.get_editor(view)
    %{cells: [cell]} = block

    Wrapper.trigger_split_block(view, block, %{
      selection: %{start_id: cell.id, end_id: cell.id, start_offset: 4, end_offset: 4}
    })

    Wrapper.flush(view)

    assert [{"h1", _, _} = h1, {"p", _, _} = p_1, {"p", _, _} = p_2] =
             view
             |> render()
             |> Floki.parse_document!()
             |> Floki.find("[data-block]")

    assert Floki.text(h1) == "This"
    assert Floki.text(p_1) == " is the title of your page"
    assert Floki.text(p_2) == "This is your first paragraph."

    assert [{"h1", _, _} = h1, {"p", _, _} = p] =
             view
             |> Wrapper.trigger_undo()
             |> Floki.parse_document!()
             |> Floki.find("[data-block]")

    assert Floki.text(h1) == "This is the title of your page"
    assert Floki.text(p) == "This is your first paragraph."

    assert [{"h1", _, _} = h1, {"p", _, _} = p_1, {"p", _, _} = p_2] =
             view
             |> Wrapper.trigger_redo()
             |> Floki.parse_document!()
             |> Floki.find("[data-block]")

    assert Floki.text(h1) == "This"
    assert Floki.text(p_1) == " is the title of your page"
    assert Floki.text(p_2) == "This is your first paragraph."
  end

  test "can split and join lines", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, Wrapper)

    %{blocks: [_, block]} = Wrapper.get_editor(view)
    %{cells: [cell]} = block

    Wrapper.trigger_split_line(view, block, %{
      selection: %{start_id: cell.id, end_id: cell.id, start_offset: 4, end_offset: 4}
    })

    Wrapper.flush(view)

    assert [{"h1", _, _} = _h1, {"p", _, [cell_1, cell_2, cell_3]} = _p] =
             view
             |> render()
             |> Floki.parse_document!()
             |> Floki.find("[data-block]")

    assert Floki.text(cell_1) == "This"
    assert [class_names] = Floki.attribute(cell_2, "class")
    assert class_names =~ "br"
    assert Floki.text(cell_3) == " is your first paragraph."

    %{blocks: [_, block]} = Wrapper.get_editor(view)
    cell_3 = Enum.at(block.cells, -1)

    Wrapper.trigger_split_line(view, block, %{
      selection: %{
        start_id: cell_3.id,
        end_id: cell_3.id,
        start_offset: String.length(cell_3.text),
        end_offset: String.length(cell_3.text)
      }
    })

    Wrapper.flush(view)

    assert [{"h1", _, _} = _h1, {"p", _, [_cell_1, _cell_2, cell_3, cell_4, cell_5]} = _p] =
             view
             |> render()
             |> Floki.parse_document!()
             |> Floki.find("[data-block]")

    assert Floki.text(cell_1) == "This"
    assert [class_names] = Floki.attribute(cell_2, "class")
    assert class_names =~ "br"
    assert Floki.text(cell_3) == " is your first paragraph."
    assert [class_names] = Floki.attribute(cell_4, "class")
    assert class_names =~ "br"
    assert Floki.text(cell_5) == " "
  end
end
