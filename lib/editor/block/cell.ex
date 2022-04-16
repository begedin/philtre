defmodule Editor.Block.Cell do
  @moduledoc """
  Represents a single cell within a block. Cells are discrete parts of a block,
  to which some style (specified by modifiers) is applied.

  The logic of a block is such that there is no nesting of cells so everything
  is just one level, separated purely to support styling.
  """
  defstruct [:id, :modifiers, :text]

  @type id :: String.t()

  @type t :: %__MODULE__{
          id: id,
          modifiers: list(String.t()),
          text: String.t()
        }
end
