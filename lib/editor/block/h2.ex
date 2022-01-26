defmodule Editor.Block.H2 do
  @moduledoc """
  Holds logic specific to the h2 block
  """

  alias Editor.Block
  alias Editor.Cell

  defdelegate newline(block, cell, index), to: Block

  @doc """
  Performs backspace operation. Downgrades block to h3.
  """
  @spec backspace(Editor.t(), Block.t(), Cell.t()) :: Editor.t()
  def backspace(%Editor{} = editor, %Block{} = block, %Cell{}) do
    Block.downgrade(editor, block, "h3")
  end
end
