defmodule Philtre.Block.List.Item do
  @moduledoc """
  Represents a single item in the list block
  """
  defstruct [:contenteditable]

  @type t :: %__MODULE__{}
end
