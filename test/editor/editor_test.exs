defmodule EditorTest do
  @moduledoc false

  use EditorTest.EditorCase

  import Phoenix.LiveViewTest

  alias Editor.Block

  @editor %Editor{
    id: "-5",
    blocks: [
      %Block.H1{id: "1", pre_caret: "Foo"},
      %Block.P{id: "2", pre_caret: "Bar"},
      %Block.P{id: "3", pre_caret: "Baz"}
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
             %Editor.Block.H1{active: false, post_caret: "", pre_caret: "Foo"},
             %Editor.Block.P{active: false, post_caret: "", pre_caret: "Bar"}
           ] = editor.clipboard

    # pasting right after first "Foo"
    Wrapper.paste_blocks(view, 0, %{pre: "Fo", post: "o"})

    editor = Wrapper.get_editor(view)
    assert Enum.count(editor.blocks) == 6

    assert %{
             blocks: [
               %Editor.Block.H1{active: false, post_caret: "", pre_caret: "Fo"},
               %Editor.Block.H1{active: false, post_caret: "", pre_caret: "Foo"},
               %Editor.Block.P{active: false, post_caret: "", pre_caret: "Bar"},
               %Editor.Block.P{active: true, post_caret: "o", pre_caret: ""},
               %Editor.Block.P{active: false, post_caret: "", pre_caret: "Bar"},
               %Editor.Block.P{active: false, post_caret: "", pre_caret: "Baz"}
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
             %Editor.Block.H1{active: false, post_caret: "", pre_caret: "Foo"},
             %Editor.Block.P{active: false, post_caret: "", pre_caret: "Bar"}
           ] = editor.clipboard

    # pasting right after first "Foo"
    Wrapper.paste_blocks(view, 0, %{pre: "Foo", post: ""})

    editor = Wrapper.get_editor(view)
    assert Enum.count(editor.blocks) == 5

    assert %{
             blocks: [
               %Editor.Block.H1{active: false, post_caret: "", pre_caret: "Foo"},
               %Editor.Block.H1{active: false, post_caret: "", pre_caret: "Foo"},
               %Editor.Block.P{active: false, post_caret: "", pre_caret: "Bar"},
               %Editor.Block.P{active: false, post_caret: "", pre_caret: "Bar"},
               %Editor.Block.P{active: false, post_caret: "", pre_caret: "Baz"}
             ]
           } = editor
  end

  test "can insert block after block", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, Wrapper)

    Wrapper.set_editor(view, Editor.new())
    Wrapper.trigger_split_block(view, Wrapper.block_at(view, 0), :end)
    assert %Block.P{pre_caret: "", post_caret: ""} = Wrapper.block_at(view, 1)
  end

  test "can convert block to h1", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, Wrapper)

    %Block.H1{} = h1 = Wrapper.block_at(view, 0)
    Wrapper.trigger_split_block(view, h1, :end)

    %Block.P{} = p = Wrapper.block_at(view, 1)
    assert %{pre_caret: "", post_caret: ""} = p

    Wrapper.trigger_update(view, p, %{pre: "# ", post: "foo"})

    assert %Block.H1{} = h1 = Wrapper.block_at(view, 1)
    assert %{pre_caret: "", post_caret: "foo"} = h1
  end

  test "can convert block to h2", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, Wrapper)

    %Block.H1{} = h1 = Wrapper.block_at(view, 0)
    Wrapper.trigger_split_block(view, h1, :end)

    %Block.P{} = p = Wrapper.block_at(view, 1)
    assert %{pre_caret: "", post_caret: ""} = p

    Wrapper.trigger_update(view, p, %{pre: "## ", post: "foo"})

    assert %Block.H2{} = h2 = Wrapper.block_at(view, 1)
    assert %{pre_caret: "", post_caret: "foo"} = h2
  end

  test "can convert block to h3", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, Wrapper)

    %Block.H1{} = h1 = Wrapper.block_at(view, 0)
    Wrapper.trigger_split_block(view, h1, :end)

    %Block.P{} = p = Wrapper.block_at(view, 1)
    assert %{pre_caret: "", post_caret: ""} = p

    Wrapper.trigger_update(view, p, %{pre: "### ", post: "foo"})

    assert %Block.H3{} = h3 = Wrapper.block_at(view, 1)
    assert %{pre_caret: "", post_caret: "foo"} = h3
  end

  test "can convert block to pre", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, Wrapper)

    %Block.H1{} = h1 = Wrapper.block_at(view, 0)
    Wrapper.trigger_split_block(view, h1, :end)

    %Block.P{} = p = Wrapper.block_at(view, 1)
    assert %{pre_caret: "", post_caret: ""} = p

    Wrapper.trigger_update(view, p, %{pre: "```", post: "foo"})

    assert %Block.Pre{} = pre = Wrapper.block_at(view, 1)
    assert %{pre_caret: "", post_caret: "foo"} = pre
  end

  test "can convert block to li", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, Wrapper)

    %Block.H1{} = h1 = Wrapper.block_at(view, 0)
    Wrapper.trigger_split_block(view, h1, :end)

    %Block.P{} = p = Wrapper.block_at(view, 1)
    assert %{pre_caret: "", post_caret: ""} = p

    Wrapper.trigger_update(view, p, %{pre: "* ", post: "foo"})

    assert %Block.Li{} = li = Wrapper.block_at(view, 1)
    assert %{pre_caret: "", post_caret: "foo"} = li
  end

  test "can downgrade h1 to h2 to h3 to p", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, Wrapper)
    assert %Block.H1{} = Wrapper.block_at(view, 0)

    Wrapper.trigger_backspace_from_start(view, 0)
    assert %Block.H2{} = Wrapper.block_at(view, 0)

    Wrapper.trigger_backspace_from_start(view, 0)
    assert %Block.H3{} = Wrapper.block_at(view, 0)

    Wrapper.trigger_backspace_from_start(view, 0)
    assert %Block.P{} = Wrapper.block_at(view, 0)
  end

  test "can downgrade li to p, merging cells", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, Wrapper)

    Wrapper.trigger_update(view, 1, %{pre: "* ", post: "foo"})
    assert %Block.Li{} = Wrapper.block_at(view, 1)

    Wrapper.trigger_backspace_from_start(view, 1)
    assert %Block.P{} = Wrapper.block_at(view, 1)
  end

  test "can downgrade pre to p", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, Wrapper)

    Wrapper.trigger_update(view, 1, %{pre: "```", post: "foo"})
    assert %Block.Pre{} = Wrapper.block_at(view, 1)

    Wrapper.trigger_backspace_from_start(view, 1)
    assert %Block.P{} = Wrapper.block_at(view, 1)
  end

  test "can merge multiple p blocks", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, Wrapper)

    Wrapper.trigger_split_block(view, 1, %{pre: "foo", post: "bar"})
    Wrapper.trigger_split_block(view, 2, %{pre: "bar", post: "baz"})

    assert %{blocks: [%Block.H1{}, %Block.P{}, %Block.P{}, %Block.P{}]} = Wrapper.get_editor(view)

    Wrapper.trigger_backspace_from_start(view, 3)
    Wrapper.trigger_backspace_from_start(view, 2)
    Wrapper.trigger_backspace_from_start(view, 1)

    assert %{blocks: [%Block.H1{}]} = Wrapper.get_editor(view)
  end
end
