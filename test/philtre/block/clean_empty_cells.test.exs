defmodule Philtre.Editor.Block.ReduceTest do
  use ExUnit.Case, async: true

  alias Philtre.Editor.Block
  alias Philtre.Editor.Block.Cell
  alias Philtre.Editor.Block.CleanEmptyCells
  alias Philtre.Editor.Block.Selection

  test "returns same block when no cells" do
    block = %Block{cells: []}
    assert CleanEmptyCells.call(block) == block
  end

  test "returns same block when one cell" do
    block = %Block{cells: [Cell.new()]}
    assert CleanEmptyCells.call(block) == block
  end

  test "out of two cells with empty content, discards the first one" do
    block = %Block{
      cells: [
        %Cell{id: "1", text: ""},
        %Cell{id: "2", text: ""}
      ]
    }

    assert %{cells: [cell]} = CleanEmptyCells.call(block)
    assert cell == Enum.at(block.cells, 1)
  end

  test "out of multiple cells with empty content, keeps the last one" do
    block = %Block{
      cells: [
        %Cell{id: "1", text: ""},
        %Cell{id: "2", text: ""},
        %Cell{id: "3", text: ""}
      ]
    }

    assert %{cells: [cell]} = CleanEmptyCells.call(block)
    assert cell == Enum.at(block.cells, 2)
  end

  test "cleans up multiple ocurrences of empty cells" do
    block = %Block{
      cells: [
        %Cell{id: "1", text: ""},
        %Cell{id: "2", text: ""},
        %Cell{id: "3", text: "foo"},
        %Cell{id: "4", text: "bar"},
        %Cell{id: "5", text: ""},
        %Cell{id: "6", text: "baz"}
      ]
    }

    assert %{cells: cells} = CleanEmptyCells.call(block)

    assert cells == [
             %Cell{id: "3", text: "foo"},
             %Cell{id: "4", text: "bar"},
             %Cell{id: "6", text: "baz"}
           ]
  end

  test "when cleaned cell had entire selection, moves it to first clean block" do
    block = %Block{
      cells: [
        %Cell{id: "1", text: ""},
        %Cell{id: "2", text: ""},
        %Cell{id: "3", text: ""}
      ],
      selection: %Selection{start_id: "1", end_id: "1", start_offset: 0, end_offset: 0}
    }

    assert %{selection: selection} = CleanEmptyCells.call(block)

    assert selection == %Selection{
             start_id: "3",
             end_id: "3",
             start_offset: 0,
             end_offset: 0
           }
  end

  test "when cleaned cell had start of selection, moves it to first clean block" do
    block = %Block{
      cells: [
        %Cell{id: "1", text: ""},
        %Cell{id: "2", text: ""},
        %Cell{id: "3", text: ""},
        %Cell{id: "4", text: "foo"}
      ],
      selection: %Selection{start_id: "1", end_id: "4", start_offset: 0, end_offset: 2}
    }

    assert %{selection: selection} = CleanEmptyCells.call(block)

    assert selection == %Selection{start_id: "4", end_id: "4", start_offset: 0, end_offset: 2}
  end
end
