defmodule Philtre.BlockRegistry do
  @moduledoc """
  Hardcoded registry for block types. Once custom blocks are possible externally,
  this will be a config- or runtime registry.
  """

  alias Philtre.Block.Code
  alias Philtre.Block.ContentEditable
  alias Philtre.Block.List
  alias Philtre.Block.Table

  @structs_by_type %{
    "code" => Code,
    "contenteditable" => ContentEditable,
    "list" => List,
    "table" => Table
  }

  def struct_for_type(type) do
    Map.fetch!(@structs_by_type, type)
  end

  @transforms %{
    "/list" => List,
    "/code" => Code,
    "/table" => Table,
    "* " => {ContentEditable, "li"},
    "# " => {ContentEditable, "h1"},
    "## " => {ContentEditable, "h2"},
    "### " => {ContentEditable, "h3"},
    "```" => {ContentEditable, "pre"},
    "> " => {ContentEditable, "blockquote"}
  }

  def transforms, do: @transforms
end
