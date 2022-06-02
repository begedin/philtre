defmodule Philtre.Block.ContentEditable.Reduce do
  @moduledoc """
  Reduces a block by merging in cells with the same styling (modifiers).

  The aim is to reduce the overall number of redundant cells and keep the output HTML as simple as
  possible.
  """
  alias Philtre.Block.ContentEditable
  alias Philtre.Block.ContentEditable.Cell
  alias Philtre.Block.ContentEditable.Selection

  @doc """
  Reduces the block by joining neighboring cells with the same modifiers.

  Since selection is defined by cell ids, it needs to be updated as well.
  """
  @spec call(ContentEditable.t()) :: ContentEditable.t()
  def call(%ContentEditable{cells: []} = block), do: block
  def call(%ContentEditable{cells: [_]} = block), do: block

  def call(%ContentEditable{cells: [first | rest]} = block) do
    {new_cells, new_selection} =
      Enum.reduce(
        rest,
        {[first], block.selection},
        fn %Cell{} = current_cell, {previous_cells, selection_or_nil} ->
          %Cell{} = previous_cell = Enum.at(previous_cells, -1)

          if Enum.sort(current_cell.modifiers) == Enum.sort(previous_cell.modifiers) do
            other_cells = Enum.drop(previous_cells, -1)
            merged = merge(previous_cell, current_cell)
            selection = update_selection(selection_or_nil, previous_cell, current_cell)

            {other_cells ++ [merged], selection}
          else
            {previous_cells ++ [current_cell], selection_or_nil}
          end
        end
      )

    %{block | cells: new_cells, selection: new_selection}
  end

  @spec merge(Cell.t(), Cell.t()) :: Cell.t()
  defp merge(%Cell{} = to, %Cell{} = from), do: %{to | text: to.text <> from.text}

  @spec update_selection(Selection.t() | nil, Cell.t(), Cell.t()) :: Selection.t() | nil

  defp update_selection(
         %Selection{} = selection,
         %Cell{} = to,
         %Cell{} = from
       ) do
    {new_start_id, new_start_offset} =
      if selection.start_id == from.id do
        {to.id, selection.start_offset + String.length(to.text)}
      else
        {selection.start_id, selection.start_offset}
      end

    {new_end_id, new_end_offset} =
      if selection.end_id == from.id do
        {to.id, selection.end_offset + String.length(to.text)}
      else
        {selection.end_id, selection.end_offset}
      end

    %Selection{
      start_id: new_start_id,
      end_id: new_end_id,
      start_offset: new_start_offset,
      end_offset: new_end_offset
    }
  end

  defp update_selection(nil, %Cell{}, %Cell{}), do: nil
end
