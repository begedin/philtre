defmodule Editor.Serializer do
  @moduledoc """
  Holds normalization and serialization logic for the editor
  """
  alias Editor.Block
  alias Editor.Utils

  @modules %{
    "p" => Block.P,
    "pre" => Block.Pre,
    "ul" => Block.Ul,
    "h1" => Block.H1,
    "blockquote" => Block.Blockquote,
    "h2" => Block.H2,
    "h3" => Block.H3
  }

  def html(%Editor{} = editor), do: Enum.map_join(editor.blocks, &html/1)
  def html(%module{} = block_or_cell), do: module.html(block_or_cell)

  def text(%Editor{} = editor), do: Enum.map_join(editor.blocks, &text/1)
  def text(%module{} = block_or_cell), do: module.text(block_or_cell)

  def serialize(%Editor{} = editor) do
    editor
    |> Map.from_struct()
    |> Map.put(:blocks, Enum.map(editor.blocks, &serialize/1))
  end

  def serialize(%module{} = block_or_cell), do: module.serialize(block_or_cell)

  def normalize(%{"blocks" => blocks} = payload) when is_list(blocks) do
    id = Map.get(payload, "id", Utils.new_id())
    %Editor{id: id, blocks: Enum.map(blocks, &normalize/1)}
  end

  def normalize(%{"type" => type} = data), do: @modules[type].normalize(data)
end
