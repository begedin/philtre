defmodule Editor.Block.Pre do
  @moduledoc """
  Holds logic specific to the pre block
  """

  alias Editor.Block
  alias Editor.Cell
  alias Editor.Page

  defdelegate newline(block, cell, index), to: Block.Base

  @doc """
  Performs backspace operation. Downgrades block to P.
  """
  @spec backspace(Page.t(), Block.t(), Cell.t()) :: Page.t()
  def backspace(%Page{} = page, %Block{} = block, %Cell{}) do
    Block.Base.downgrade(page, block)
  end
end
