defmodule Editor.Block.Selection do
  @moduledoc """
  Holds current selection in a block.

  Passed from client to backend and vice-versa when executing block commands.

  The ids are ids of cells in which a selection starts or ends.
  The offests are indices within those cells where the selection starts or ends.

  That means a simple caret (a cursor somewhere in the block text) will have
  the same ids and same offsets.

  Similarly, a selection of a text within a single cell will have the same ids,
  but different offsets.

  Lastly, a selection across cells within a block will have different ids and
  different offsets.

  Selection across blocks is not possible. Only whole blocks can be selected and
  this is handled at a different level.
  """
  alias Editor.Block
  defstruct [:start_id, :end_id, :start_offset, :end_offset]

  @type t :: %__MODULE__{
          start_id: Block.Cell.id() | nil,
          end_id: Block.Cell.id() | nil,
          start_offset: non_neg_integer() | nil,
          end_offset: non_neg_integer() | nil
        }
end
