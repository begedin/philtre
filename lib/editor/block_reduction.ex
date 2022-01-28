defmodule Editor.BlockReduction do
  @moduledoc """
  Performs reduction operation on a block, collapsing all adjacent cells of the
  same type into one.
  """
  alias Editor.Block
  alias Editor.Cell

  defstruct [:new_block, :active_cell_id, :cursor_index]

  @type t :: %__MODULE__{}

  @spec perform(Block.t(), Cell.id(), non_neg_integer()) :: t
  def perform(%Block{} = block, cell_id, cursor_index) do
    [first | rest] = block.cells

    {cells, cursor_index, active_cell_id} =
      Enum.reduce(
        rest,
        {[first], cursor_index, nil},
        fn %Cell{} = cell, {cells, cursor_index, active_cell_id} ->
          [%Cell{} = previous | rest] = Enum.reverse(cells)

          if previous.type == cell.type do
            cursor_index =
              if active_cell_id do
                cursor_index
              else
                cursor_index + String.length(previous.content)
              end

            previous = Cell.join(cell, previous)
            cells = Enum.reverse([previous | rest])

            active_cell_id = if cell.id === cell_id, do: previous.id, else: active_cell_id

            {cells, cursor_index, active_cell_id}
          else
            cursor_index =
              if active_cell_id do
                cursor_index
              else
                cursor_index + String.length(cell.content)
              end

            cells = Enum.reverse([cell, previous] ++ rest)

            active_cell_id = if cell.id === cell_id, do: cell.id, else: active_cell_id

            {cells, cursor_index, active_cell_id}
          end
        end
      )

    %__MODULE__{
      new_block: %{block | cells: cells},
      active_cell_id: active_cell_id,
      cursor_index: cursor_index
    }
  end
end
