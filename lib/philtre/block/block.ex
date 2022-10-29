defmodule Philtre.Block do
  @moduledoc """
  Defines what the structure of a block should be
  """

  alias Philtre.Block.ContentEditable
  alias Philtre.Block.ContentEditable.Selection

  @doc """
  Takes the struct for the specific block type and returns its id
  """
  @callback id(struct) :: String.t()

  @doc """
  Takes the struct for the specific block type and returns its string type
  """
  @callback type(struct) :: String.t()

  @doc """
  Takes the struct for the specific block type and returns its data serialized
  as a json-encodeable map with string keys.
  """
  @callback data(struct) :: %{required(String.t()) => any}

  @doc """
  Takes in the block id and the serialized data and returns the struct for the
  block.
  """
  @callback normalize(String.t(), any) :: struct

  @doc """
  Used to set a selection (focus cursor) on the block
  """
  @callback set_selection(struct, Selection.t()) :: struct

  @doc """
  Used to simplify and cleanup the block, remove blank fields, etc.
  """
  @callback reduce(struct) :: struct

  @doc """
  Returns a list of base cells contained within the block
  """
  @callback cells(struct) :: list(ContentEditable.Cell.t())

  @doc """
  Used to transform the contenteditable block into the current block
  """
  @callback transform(ContentEditable.t()) :: struct

  @doc """
  Renderer for the live, interactive version of the block, when editing
  """
  @callback render_live(%{required(:block) => struct}) :: Phoenix.LiveView.Rendered.t()

  @doc """
  Renderer for the static, read-only version of the block, when rendering as plain html
  """
  @callback render_static(%{required(:block) => struct}) :: Phoenix.LiveView.Rendered.t()
end
