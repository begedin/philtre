defmodule Editor.Block.P do
  @moduledoc """
  Holds logic specific to the p block
  """

  alias Editor.Block

  defdelegate newline(block, cell, index), to: Block.Base
  defdelegate backspace(editor, block, cell), to: Block.Base
end
