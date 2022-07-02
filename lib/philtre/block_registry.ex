defmodule Philtre.BlockRegistry do
  @moduledoc """
  Hardcoded registry for block types. Once custom blocks are possible externally,
  this will be a config- or runtime registry.
  """

  alias Philtre.Block.Code
  alias Philtre.Block.ContentEditable
  alias Philtre.Block.Table

  @structs_by_type %{
    "contenteditable" => ContentEditable,
    "table" => Table,
    "code" => Code
  }

  def struct_for_type(type) do
    Map.fetch!(@structs_by_type, type)
  end
end
