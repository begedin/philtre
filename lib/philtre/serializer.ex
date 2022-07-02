defmodule Philtre.Editor.Serializer do
  @moduledoc """
  Holds normalization and serialization logic for the editor
  """

  alias Philtre.BlockRegistry
  alias Philtre.Editor
  alias Philtre.StaticBlock

  def serialize(%Editor{} = editor) do
    %{"id" => editor.id, "blocks" => Enum.map(editor.blocks, &serialize/1)}
  end

  @spec serialize(struct) :: map
  def serialize(%struct{} = block) do
    %{"id" => struct.id(block), "type" => struct.type(block), "data" => struct.data(block)}
  end

  def normalize(%{"id" => id, "blocks" => blocks}) when is_binary(id) and is_list(blocks) do
    %Editor{id: id, blocks: Enum.map(blocks, &normalize/1)}
  end

  def normalize(%{"blocks" => blocks} = params) when is_list(blocks) do
    params |> Map.put("id", Editor.Utils.new_id()) |> normalize()
  end

  def normalize(%{"id" => id, "type" => type, "data" => data}) do
    struct = BlockRegistry.struct_for_type(type)
    struct.normalize(id, data)
  end

  def text(%Editor{} = editor) do
    editor |> html() |> Floki.parse_document!() |> Floki.text()
  end

  def html(%Editor{blocks: blocks}), do: Enum.map_join(blocks, "", &html/1)

  def html(%_{} = block) do
    %{block: block}
    |> StaticBlock.render()
    |> Phoenix.HTML.html_escape()
    |> Phoenix.HTML.safe_to_string()
  end
end
