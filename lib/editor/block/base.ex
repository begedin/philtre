defmodule Editor.Block.Base do
  @moduledoc """
  Handles base logic around blocks.
  """

  alias Editor.Block
  alias Editor.Cell
  alias Editor.SplitResult

  @doc """
  Performs basic newline operation.

  This operation will always effectively split the entire page at the target
  index of the target cell.

  The cell will be split in two. The block containing it will also be split in two. The first part
  of the split cell, as well as the cells preceding it will go to the first block. The second part
  of the cell and the cells following it will go to the second block.
  """
  @spec newline(Block.t(), Cell.t(), integer) :: SplitResult.t()
  def newline(%Block{} = block, %Cell{} = cell, index) do
    {cells_before, cells_after} = split_around_cell(block.cells, cell)
    {cell_before, cell_after} = split_cell(cell, index)

    %Cell{id: active_cell_id} = cell_after

    new_blocks = [
      %Block{block | cells: cells_before ++ [cell_before]},
      %Block{Block.new("p") | cells: [cell_after] ++ cells_after}
    ]

    %SplitResult{
      active_cell_id: active_cell_id,
      cursor_index: 0,
      new_blocks: new_blocks
    }
  end

  @doc """
  Splits a list of cells around the specified cell.

  Returns a tuple of to lists of cells. The left
  list contains cells preceeding the specified cell, the right the ones following it.

  The specified cell is excluded from the results.
  """
  @spec split_around_cell(list(Cell.t()), Cell.t()) :: {list(Cell.t()), list(Cell.t())}
  def split_around_cell(cells, %Cell{} = cell) do
    cell_index = Enum.find_index(cells, &(&1.id === cell.id))
    cells |> Enum.reject(&(&1 === cell)) |> Enum.split(cell_index)
  end

  @doc """
  Splits the specified cell into two cells at the target index
  """
  @spec split_cell(Cell.t(), integer) :: {Cell.t(), Cell.t()}
  def split_cell(%Cell{} = cell, index) do
    {content_before, content_after} = String.split_at(cell.content, index)
    {Cell.new(cell.type, content_before), Cell.new(cell.type, content_after)}
  end
end
