defmodule Philtre.Block.ContentEditable.CleanEmptyCells do
  @moduledoc """
  Cleans up empty cells from a block.

  Various block actions will result in empty cells being left over. These are
  redundant and can be removed without any consequences, resulting in a simpler
  html.
  """
  alias Philtre.Block.ContentEditable
  alias Philtre.Block.ContentEditable.Cell
  alias Philtre.Block.ContentEditable.Selection

  @doc """
  Removes empty cells from a block.

  Since a new block must contain an empty cell, that one is not cleaned up in
  this scenario.

  If block selection starts and/or ends within a cleaned up cell, that edge of
  selection is moved into the next appropriate cell.
  """
  @spec call(ContentEditable.t()) :: ContentEditable.t()
  def call(%ContentEditable{cells: []} = block), do: block
  def call(%ContentEditable{cells: [_]} = block), do: block

  def call(%ContentEditable{} = block) do
    {new_cells, new_selection} = clean([], block.cells, block.selection)
    %{block | cells: new_cells, selection: new_selection}
  end

  @spec clean(
          list(Cell.t()),
          list(Cell.t()),
          Selection.t() | nil
        ) :: {list(Cell.t()), Selection.t() | nil}
  defp clean(cleaned, [%Cell{} = current, %Cell{} = next | rest], selection_or_nil) do
    if current.text === "" do
      selection = move_selection(selection_or_nil, current, next)
      clean(cleaned, [next] ++ rest, selection)
    else
      clean(cleaned ++ [current], [next] ++ rest, selection_or_nil)
    end
  end

  defp clean(cleaned, uncleaned, selection_or_nil), do: {cleaned ++ uncleaned, selection_or_nil}

  @spec move_selection(Selection.t() | nil, Cell.t(), Cell.t()) :: Selection.t()
  defp move_selection(nil, %Cell{}, %Cell{}), do: nil
  defp move_selection(%Selection{start_id: nil} = selection, %Cell{}, %Cell{}), do: selection

  defp move_selection(%Selection{} = selection, %Cell{} = cleaned_cell, %Cell{} = new_cell) do
    {new_start_id, new_start_offset} =
      if selection.start_id == cleaned_cell.id do
        {new_cell.id, 0}
      else
        {selection.start_id, selection.start_offset}
      end

    {new_end_id, new_end_offset} =
      if selection.end_id == cleaned_cell.id do
        {new_cell.id, 0}
      else
        {selection.end_id, selection.end_offset}
      end

    %Selection{
      start_id: new_start_id,
      start_offset: new_start_offset,
      end_id: new_end_id,
      end_offset: new_end_offset
    }
  end
end
