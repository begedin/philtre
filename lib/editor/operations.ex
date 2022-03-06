defmodule Editor.Operations do
  @moduledoc """
  Represents the entire content of a single record written in an editor.
  """

  alias Editor.Block
  alias Editor.Utils

  @type id :: Utils.id()
  @type block :: Block.t()
end
