defmodule EditorTest do
  @moduledoc false

  use EditorTest.EditorCase

  import Phoenix.LiveViewTest

  alias Editor.Block

  @editor %Editor{
    blocks: [
      %Block.H1{id: "1", pre_caret: "Foo"},
      %Block.P{id: "2", pre_caret: "Bar"},
      %Block.P{id: "3", pre_caret: "Baz"}
    ]
  }

  test "can select,then copy and paste blocks", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, Wrapper)

    Wrapper.set_editor(view, @editor)

    block_ids = @editor.blocks |> Enum.map(& &1.id) |> Enum.take(2)

    Wrapper.select_blocks(view, block_ids)

    editor = Wrapper.get_editor(view)
    assert editor.selected_blocks == block_ids

    Wrapper.copy_blocks(view, block_ids)

    editor = Wrapper.get_editor(view)
    assert editor.clipboard == Enum.take(@editor.blocks, 2)

    # pasting right after first "Foo"
    Wrapper.paste_blocks(view, %{cell_id: "11", index: 3})

    editor = Wrapper.get_editor(view)
    assert Enum.count(editor.blocks) == 6
    assert editor == "FooFooBarBarBaz"
  end

  test "can insert block after block", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, Wrapper)

    Wrapper.set_editor(view, Editor.new())
    Wrapper.newline(view, Wrapper.block_at(view, 0), :end_of_last_cell)
    assert %{type: "p", cells: [_]} = Wrapper.block_at(view, 1)
  end

  test "can convert block to h1", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, Wrapper)

    %{type: "h1"} = h1 = Wrapper.block_at(view, 0)
    Wrapper.newline(view, h1, :end_of_last_cell)

    %{type: "p", cells: [cell]} = Wrapper.block_at(view, 1)
    Wrapper.push_content(view, cell, "# foo")

    assert %{type: "h1", cells: [cell]} = Wrapper.block_at(view, 1)
    assert cell.content == "foo"
  end

  test "can convert block to h2", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, Wrapper)

    Wrapper.set_editor(view, Editor.new())

    %{type: "h1"} = h1 = Wrapper.block_at(view, 0)
    Wrapper.newline(view, h1, :end_of_last_cell)

    %{type: "p", cells: [cell]} = Wrapper.block_at(view, 1)
    Wrapper.push_content(view, cell, "## foo")

    assert %{type: "h2", cells: [cell]} = Wrapper.block_at(view, 1)
    assert cell.content == "foo"
  end

  test "can convert block to h3", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, Wrapper)

    %{type: "h1"} = h1 = Wrapper.block_at(view, 0)
    Wrapper.newline(view, h1, :end_of_last_cell)

    %{type: "p", cells: [cell]} = Wrapper.block_at(view, 1)
    Wrapper.push_content(view, cell, "### foo")

    assert %{type: "h3", cells: [cell]} = Wrapper.block_at(view, 1)
    assert cell.content == "foo"
  end

  test "can convert block to pre", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, Wrapper)

    %{type: "h1"} = h1 = Wrapper.block_at(view, 0)
    Wrapper.newline(view, h1, :end_of_last_cell)

    %{type: "p", cells: [cell]} = Wrapper.block_at(view, 1)
    Wrapper.push_content(view, cell, "```foo")

    assert %{type: "pre", cells: [cell]} = Wrapper.block_at(view, 1)
    assert cell.content == "foo"
  end

  test "can convert block to ul", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, Wrapper)

    %{type: "h1"} = h1 = Wrapper.block_at(view, 0)
    Wrapper.newline(view, h1, :end_of_last_cell)

    %{type: "p", cells: [cell]} = Wrapper.block_at(view, 1)
    Wrapper.push_content(view, cell, "* foo")

    assert %{type: "ul", cells: [cell]} = Wrapper.block_at(view, 1)
    assert cell.content == "foo"
    assert cell.type == "li"
  end

  test "can downgrade h1 to h2 to h3 to p", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, Wrapper)
    assert %{type: "h1"} = h1 = Wrapper.block_at(view, 0)

    Wrapper.downgrade_block(view, h1)
    assert %{type: "h2"} = h2 = Wrapper.block_at(view, 0)

    Wrapper.downgrade_block(view, h2)
    assert %{type: "h3"} = h3 = Wrapper.block_at(view, 0)

    Wrapper.downgrade_block(view, h3)
    assert %{type: "p"} = Wrapper.block_at(view, 0)
  end

  test "can downgrade ul to p, merging cells", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, Wrapper)
    Wrapper.newline(view, :end_of_page)
    Wrapper.push_content(view, :end_of_page, "* foo")
    Wrapper.newline(view, :end_of_page)
    Wrapper.push_content(view, :end_of_page, "bar")
    Wrapper.newline(view, :end_of_page)
    Wrapper.push_content(view, :end_of_page, "baz")

    assert Wrapper.block_types(view) === ["h1", "ul"]
    %Block.Li{} = ul = Wrapper.block_at(view, 1)
    Wrapper.backspace(view, ul, :start_of_first_cell)

    assert Wrapper.block_types(view) === ["h1", "p"]
    assert Wrapper.block_text(view, 1) === "foobarbaz"

    assert view |> Wrapper.block_at(1) |> Wrapper.cell_types() === ["span"]
  end

  test "can downgrade pre to p", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, Wrapper)
    Wrapper.newline(view, :end_of_page)
    Wrapper.push_content(view, :end_of_page, "```foo")

    assert Wrapper.block_types(view) === ["h1", "pre"]
    %Block.Pre{} = pre = Wrapper.block_at(view, 1)
    Wrapper.backspace(view, pre, :start_of_first_cell)

    assert Wrapper.block_types(view) === ["h1", "p"]
    assert Wrapper.block_text(view, 1) === "foo"
  end

  test "can merge multiple p blocks", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, Wrapper)

    Wrapper.newline(view, :end_of_page)
    Wrapper.push_content(view, :end_of_page, "foo")
    Wrapper.newline(view, :end_of_page)
    Wrapper.push_content(view, :end_of_page, "bar")
    Wrapper.newline(view, :end_of_page)
    Wrapper.push_content(view, :end_of_page, "baz")

    assert Wrapper.block_types(view) === ["h1", "p", "p", "p"]

    %Block.P{} = p = Wrapper.block_at(view, 2)
    Wrapper.backspace(view, p, :start_of_first_cell)
    assert Wrapper.block_types(view) === ["h1", "p", "p"]
    assert Wrapper.block_text(view, 1) === "foobar"
    assert view |> Wrapper.block_at(1) |> Wrapper.cell_types() === ["span"]
    assert Wrapper.cursor_index(view) === 3
    assert Wrapper.active_cell_id(view) === Wrapper.cell_at(view, 1, 0).id

    %Block.P{} = p = Wrapper.block_at(view, 1)
    Wrapper.backspace(view, p, :start_of_first_cell)
    assert Wrapper.block_types(view) === ["h1", "p"]
    assert Wrapper.block_text(view, 0) === "This is the title of your pagefoobar"
    assert Wrapper.block_text(view, 1) === "baz"
  end
end
