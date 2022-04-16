defmodule Editor.Block.Cell do
  defstruct [:id, :modifiers, :text]

  @type t :: %{
          required(:id) => Utils.id(),
          required(:modifiers) => list(String.t()),
          required(:text) => String.t()
        }
end
