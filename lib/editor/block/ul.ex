defmodule Editor.Block.Ul do
  @moduledoc """
  Handles logic for a "ul" block
  """
  alias Editor.Block
  alias Editor.Cell
  alias Editor.SplitResult

  @doc """
  Handles newline command for a UL block.

  Ul blocks exibit the following behavior:

  - newline from an empty "li" discards that "li" and starts a new "p" block
  - newline from a non-empty "li" cell splits that cell into two separate cells along the index
  """
  @spec newline(Block.t(), Cell.t(), integer) :: SplitResult.t()
  def newline(%Block{type: "ul"} = block, %Cell{} = cell, index) do
    if Enum.at(block.cells, -1) == cell and cell.content == "" do
      add_p_block(block)
    else
      split_cell(block, cell, index)
    end
  end

  @spec add_p_block(Block.t()) :: SplitResult.t()
  defp add_p_block(%Block{} = block) do
    block = %{block | cells: Enum.drop(block.cells, -1)}
    %Block{} = new_p_block = Block.new("p")

    [%Cell{id: active_cell_id}] = new_p_block.cells

    %SplitResult{
      active_cell_id: active_cell_id,
      cursor_index: 0,
      new_blocks: [block, new_p_block]
    }
  end

  @spec split_cell(Block.t(), Cell.t(), integer) :: SplitResult.t()
  defp split_cell(%Block{} = block, %Cell{} = cell, index) do
    {cells_before, cells_after} = Block.Base.split_around_cell(block.cells, cell)
    {cell_before, cell_after} = Block.Base.split_cell(cell, index)

    %Cell{id: active_cell_id} = cell_after

    new_cells =
      List.flatten([
        cells_before,
        cell_before,
        cell_after,
        cells_after
      ])

    new_block = %{block | cells: new_cells}

    %SplitResult{
      active_cell_id: active_cell_id,
      cursor_index: 0,
      new_blocks: [new_block]
    }
  end
end
