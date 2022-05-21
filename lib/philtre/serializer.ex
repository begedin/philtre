defmodule Philtre.Editor.Serializer do
  @moduledoc """
  Holds normalization and serialization logic for the editor
  """
  alias Philtre.Editor
  alias Philtre.Editor.Block
  alias Philtre.Table

  def serialize(%Editor{} = editor) do
    %{
      "id" => editor.id,
      "blocks" => Enum.map(editor.blocks, &serialize/1)
    }
  end

  @types [
    "p",
    "h1",
    "h2",
    "h3",
    "blockquote",
    "pre",
    "li"
  ]

  @spec serialize(struct) :: map
  def serialize(%Block{id: id, type: type, cells: cells})
      when type in @types do
    %{"id" => id, "type" => type, "content" => Enum.map(cells, &serialize/1)}
  end

  def serialize(%Block.Cell{id: id, modifiers: modifiers, text: text}) do
    %{"id" => id, "modifiers" => modifiers, "text" => text}
  end

  def serialize(%Philtre.Table{} = table) do
    %{"id" => table.id, "rows" => table.rows, "type" => "table"}
  end

  def normalize(%{"id" => id, "blocks" => blocks}) when is_binary(id) and is_list(blocks) do
    %Editor{id: id, blocks: Enum.map(blocks, &normalize/1)}
  end

  def normalize(%{"blocks" => blocks} = params) when is_list(blocks) do
    params |> Map.put("id", Editor.Utils.new_id()) |> normalize()
  end

  def normalize(%{"id" => id, "type" => type, "content" => content}) when type in @types do
    %Block{id: id, type: type, cells: Enum.map(content, &normalize/1)}
  end

  def normalize(%{"id" => id, "modifiers" => modifiers, "text" => text}) do
    %Block.Cell{id: id, modifiers: modifiers, text: text}
  end

  def normalize(%{"id" => id, "type" => "table", "rows" => rows}) do
    %Philtre.Table{
      id: id,
      rows: rows
    }
  end

  def text(%Editor{} = editor) do
    Enum.map_join(editor.blocks, "", &text/1)
  end

  def text(%Block{cells: _} = block) do
    block |> html |> Floki.parse_document!() |> Floki.text()
  end

  def html(%Editor{blocks: blocks}) do
    Enum.map_join(blocks, "", &html/1)
  end

  def html(%Block{cells: cells, type: tag}) do
    "<#{tag}>" <> Enum.map_join(cells, "", &html/1) <> "</#{tag}>"
  end

  def html(%Block.Cell{id: _id, modifiers: _modifiers, text: text}) do
    "<span>" <> text <> "</span>"
  end

  def html(%Table{} = table) do
    Table.html(table)
  end
end
