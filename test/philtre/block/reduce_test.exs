defmodule Philtre.Editor.Block.ReduceTest do
  use ExUnit.Case, async: true

  alias Philtre.Editor.Block
  alias Philtre.Editor.Block.Cell
  alias Philtre.Editor.Block.Reduce
  alias Philtre.Editor.Block.Selection

  test "returns same block when no cells" do
    block = %Block{cells: []}
    assert Reduce.call(block) == block
  end

  test "returns same block when one cell" do
    block = %Block{cells: [Cell.new()]}
    assert Reduce.call(block) == block
  end

  test "returns same block when nothing to reduce" do
    block = %Block{
      cells: [
        %Cell{text: "foo", modifiers: []},
        %Cell{text: "bar", modifiers: ["strong"]}
      ]
    }

    assert Reduce.call(block) == block
  end

  test "merges two mergeable cells" do
    block = %Block{
      cells: [
        %Cell{text: "foo", modifiers: []},
        %Cell{text: "bar", modifiers: []}
      ]
    }

    assert %{cells: [%{text: "foobar"}]} = Reduce.call(block)
  end

  test "merges more than two mergeable cells" do
    block = %Block{
      cells: [
        %Cell{text: "foo", modifiers: []},
        %Cell{text: "bar", modifiers: []},
        %Cell{text: "baz", modifiers: []}
      ]
    }

    assert %{cells: [%{text: "foobarbaz"}]} = Reduce.call(block)
  end

  test "merges multiple sets of mergeable cells" do
    block = %Block{
      cells: [
        %Cell{text: "foo", modifiers: []},
        %Cell{text: "bar", modifiers: []},
        %Cell{text: "baz", modifiers: []},
        %Cell{text: "bam", modifiers: ["strong"]},
        %Cell{text: "bat", modifiers: ["strong"]}
      ]
    }

    assert %{cells: [%{text: "foobarbaz"}, %{text: "bambat"}]} = Reduce.call(block)
  end

  test "updates selection when it's exclusively in the merged cell" do
    block = %Block{
      cells: [
        %Cell{id: "1", text: "foo", modifiers: []},
        %Cell{id: "2", text: "bar", modifiers: []}
      ],
      # text "ar" in cell "2" is selected
      selection: %Selection{
        start_id: "2",
        end_id: "2",
        start_offset: 1,
        end_offset: 2
      }
    }

    assert %{selection: selection} = Reduce.call(block)
    assert selection == %Selection{start_id: "1", end_id: "1", start_offset: 4, end_offset: 5}
  end

  test "updates selection when it spans to and from cell" do
    block = %Block{
      cells: [
        %Cell{id: "1", text: "foo", modifiers: []},
        %Cell{id: "2", text: "bar", modifiers: []}
      ],
      # text "ar" in cell "2" is selected
      selection: %Selection{
        start_id: "1",
        end_id: "2",
        start_offset: 1,
        end_offset: 2
      }
    }

    assert %{selection: selection} = Reduce.call(block)
    assert selection == %Selection{start_id: "1", end_id: "1", start_offset: 1, end_offset: 5}
  end

  test "updates selection when it starts in from cell and ends in another cell" do
    block = %Block{
      cells: [
        %Cell{id: "1", text: "foo", modifiers: []},
        %Cell{id: "2", text: "bar", modifiers: []},
        %Cell{id: "3", text: "baz", modifiers: ["strong"]}
      ],
      selection: %Selection{start_id: "2", end_id: "3", start_offset: 1, end_offset: 2}
    }

    assert %{selection: selection} = Reduce.call(block)
    assert selection == %Selection{start_id: "1", end_id: "3", start_offset: 4, end_offset: 2}
  end

  test "updates selection when it starts in another cell and ends in from cell" do
    block = %Block{
      cells: [
        %Cell{id: "1", text: "foo", modifiers: ["strong"]},
        %Cell{id: "2", text: "bar", modifiers: []},
        %Cell{id: "3", text: "baz", modifiers: []}
      ],
      selection: %Selection{start_id: "1", end_id: "3", start_offset: 1, end_offset: 2}
    }

    assert %{selection: selection} = Reduce.call(block)
    assert selection == %Selection{start_id: "1", end_id: "2", start_offset: 1, end_offset: 5}
  end
end
