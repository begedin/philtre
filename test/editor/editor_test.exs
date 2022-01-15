defmodule EditorTest do
  @moduledoc false

  use EditorTest.EditorCase

  import Phoenix.LiveViewTest

  @page %Editor.Page{
    blocks: [
      %Editor.Block{
        id: "1",
        type: "h1",
        cells: [%Editor.Cell{id: "11", type: "span", content: "Foo"}]
      },
      %Editor.Block{
        id: "2",
        type: "p",
        cells: [%Editor.Cell{id: "22", type: "span", content: "Bar"}]
      },
      %Editor.Block{
        id: "3",
        type: "p",
        cells: [%Editor.Cell{id: "33", type: "span", content: "Baz"}]
      }
    ]
  }

  test "can select,then copy and paste blocks", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, Wrapper)

    Wrapper.set_editor(view, %{Editor.new() | page: @page})

    block_ids = @page.blocks |> Enum.map(& &1.id) |> Enum.take(2)

    Wrapper.select_blocks(view, block_ids)

    editor = Wrapper.get_editor(view)
    assert editor.selected_blocks == block_ids

    Wrapper.copy_blocks(view, block_ids)

    editor = Wrapper.get_editor(view)
    assert editor.clipboard == Enum.take(@page.blocks, 2)

    # pasting right after first "Foo"
    Wrapper.paste_blocks(view, %{cell_id: "11", index: 3})

    editor = Wrapper.get_editor(view)
    assert Enum.count(editor.page.blocks) == 6
    assert Editor.text(editor.page) == "FooFooBarBarBaz"
  end

  test "can insert block after block", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, Wrapper)

    Wrapper.set_editor(view, Editor.new())
    Wrapper.insert_block_after(view, Wrapper.get_block_at(view, 0))
    assert %{type: "p", cells: [_]} = Wrapper.get_block_at(view, 1)
  end

  test "can convert block to h1", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, Wrapper)

    %{type: "h1"} = h1 = Wrapper.get_block_at(view, 0)
    Wrapper.insert_block_after(view, h1)

    %{type: "p", cells: [cell]} = Wrapper.get_block_at(view, 1)
    Wrapper.update_cell(view, cell, "# foo")

    assert %{type: "h1", cells: [cell]} = Wrapper.get_block_at(view, 1)
    assert cell.content == "foo"
  end

  test "can convert block to h2", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, Wrapper)

    Wrapper.set_editor(view, Editor.new())

    %{type: "h1"} = h1 = Wrapper.get_block_at(view, 0)
    Wrapper.insert_block_after(view, h1)

    %{type: "p", cells: [cell]} = Wrapper.get_block_at(view, 1)
    Wrapper.update_cell(view, cell, "## foo")

    assert %{type: "h2", cells: [cell]} = Wrapper.get_block_at(view, 1)
    assert cell.content == "foo"
  end

  test "can convert block to h3", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, Wrapper)

    %{type: "h1"} = h1 = Wrapper.get_block_at(view, 0)
    Wrapper.insert_block_after(view, h1)

    %{type: "p", cells: [cell]} = Wrapper.get_block_at(view, 1)
    Wrapper.update_cell(view, cell, "### foo")

    assert %{type: "h3", cells: [cell]} = Wrapper.get_block_at(view, 1)
    assert cell.content == "foo"
  end

  test "can convert block to pre", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, Wrapper)

    %{type: "h1"} = h1 = Wrapper.get_block_at(view, 0)
    Wrapper.insert_block_after(view, h1)

    %{type: "p", cells: [cell]} = Wrapper.get_block_at(view, 1)
    Wrapper.update_cell(view, cell, "```foo")

    assert %{type: "pre", cells: [cell]} = Wrapper.get_block_at(view, 1)
    assert cell.content == "foo"
  end

  test "can convert block to ul", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, Wrapper)

    %{type: "h1"} = h1 = Wrapper.get_block_at(view, 0)
    Wrapper.insert_block_after(view, h1)

    %{type: "p", cells: [cell]} = Wrapper.get_block_at(view, 1)
    Wrapper.update_cell(view, cell, "* foo")

    assert %{type: "ul", cells: [cell]} = Wrapper.get_block_at(view, 1)
    assert cell.content == "foo"
    assert cell.type == "li"
  end

  test "can downgrade h1 to h2 to h3 to p", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, Wrapper)
    assert %{type: "h1"} = h1 = Wrapper.get_block_at(view, 0)

    Wrapper.downgrade_block(view, h1)
    assert %{type: "h2"} = h2 = Wrapper.get_block_at(view, 0)

    Wrapper.downgrade_block(view, h2)
    assert %{type: "h3"} = h3 = Wrapper.get_block_at(view, 0)

    Wrapper.downgrade_block(view, h3)
    assert %{type: "p"} = Wrapper.get_block_at(view, 0)
  end
end
