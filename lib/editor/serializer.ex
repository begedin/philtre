defmodule Editor.Serializer do
  @moduledoc """
  Holds normalization and serialization logic for the editor
  """

  def html(%Editor{} = editor) do
    Enum.map_join(editor.blocks, &html/1)
  end

  def html(%Editor.Block{} = block) do
    cell_html = Enum.map_join(block.cells, &html/1)
    "<#{block.type}>#{cell_html}</#{block.type}>"
  end

  def html(%Editor.Cell{} = cell) do
    "<#{cell.type}>#{cell.content}</#{cell.type}>"
  end

  def text(%Editor{} = editor) do
    Enum.map_join(editor.blocks, &text/1)
  end

  def text(%Editor.Block{} = block) do
    Enum.map_join(block.cells, &text/1)
  end

  def text(%Editor.Cell{content: content}), do: content

  def serialize(%Editor{} = editor) do
    editor
    |> Map.from_struct()
    |> Map.put(:blocks, Enum.map(editor.blocks, &serialize/1))
  end

  def serialize(%Editor.Block{} = block) do
    block
    |> Map.from_struct()
    |> Map.put(:cells, Enum.map(block.cells, &serialize/1))
  end

  def serialize(%Editor.Cell{} = cell) do
    Map.from_struct(cell)
  end

  def normalize(%{"blocks" => blocks}) when is_list(blocks) do
    normalize(%{blocks: blocks})
  end

  def normalize(%{blocks: blocks}) when is_list(blocks) do
    %Editor{blocks: Enum.map(blocks, &normalize/1)}
  end

  def normalize(%{"cells" => cells, "id" => id, "type" => type})
      when is_list(cells) and is_binary(id) and is_binary(type) do
    normalize(%{cells: cells, id: id, type: type})
  end

  def normalize(%{cells: cells, id: id, type: type})
      when is_list(cells) and is_binary(id) and is_binary(type) do
    %Editor.Block{
      id: id,
      type: type,
      cells: Enum.map(cells, &normalize/1)
    }
  end

  def normalize(%{"content" => content, "id" => id, "type" => type})
      when is_binary(content) and is_binary(id) and is_binary(type) do
    normalize(%{content: content, id: id, type: type})
  end

  def normalize(%{content: content, id: id, type: type})
      when is_binary(content) and is_binary(id) and is_binary(type) do
    %Editor.Cell{id: id, type: type, content: content}
  end
end
