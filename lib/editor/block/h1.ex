defmodule Editor.Block.H1 do
  @moduledoc """
  Holds logic specific to the h1 block
  """

  alias Editor.Block
  alias Editor.Cell

  defdelegate newline(block, cell, index), to: Block.Base

  @doc """
  Performs backspace operation. Downgrades block to h2.
  """
  @spec backspace(Editor.t(), Block.t(), Cell.t()) :: Editor.t()
  def backspace(%Editor{} = editor, %Block{} = block, %Cell{}) do
    Block.Base.downgrade(editor, block, "h2")
  end
end
