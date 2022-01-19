defmodule Editor.SplitResult do
  @moduledoc """
  Defines structure of the result of splitting a block along an index in a cell
  """
  alias Editor.Block
  alias Editor.Cell

  defstruct [:new_blocks, :active_cell_id, :cursor_index]

  @type t :: %__MODULE__{
          new_blocks: list(Block.t()),
          active_cell_id: Cell.id(),
          cursor_index: integer
        }
end
