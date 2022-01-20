defmodule Editor.Block.H2 do
  @moduledoc """
  Holds logic specific to the h2 block
  """

  alias Editor.Block
  alias Editor.Cell
  alias Editor.Page

  defdelegate newline(block, cell, index), to: Block.Base

  @doc """
  Performs backspace operation. Downgrades block to h3.
  """
  @spec backspace(Page.t(), Block.t(), Cell.t()) :: Page.t()
  def backspace(%Page{} = page, %Block{} = block, %Cell{}) do
    Block.Base.downgrade(page, block, "h3")
  end
end
