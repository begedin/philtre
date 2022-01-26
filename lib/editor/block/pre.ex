defmodule Editor.Block.Pre do
  @moduledoc """
  Holds logic specific to the pre block
  """

  alias Editor.Block
  alias Editor.Cell

  defdelegate newline(block, cell, index), to: Block

  @doc """
  Performs backspace operation. Downgrades block to P.
  """
  @spec backspace(Editor.t(), Block.t(), Cell.t()) :: Editor.t()
  def backspace(%Editor{} = editor, %Block{} = block, %Cell{}) do
    Block.downgrade(editor, block)
  end
end
