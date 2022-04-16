defmodule Editor.Serializer do
  @moduledoc """
  Holds normalization and serialization logic for the editor
  """
  alias Editor.Block

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
    %{"id" => id, "type" => type, "content" => cells}
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
    %{id: id, modifiers: modifiers, text: text}
  end

  def text(%Editor{} = editor) do
    Enum.map_join(editor.blocks, "", &text/1)
  end

  def text(%Block{cells: _} = block) do
    block |> html |> Floki.parse_document!() |> Floki.text()
  end

  def html(%Block{cells: cells, type: tag}) do
    "<#{tag}>" <> (cells |> Enum.map(&html/1) |> Enum.join("")) <> "</#{tag}>"
  end

  def html(%{id: _id, modifiers: _modifiers, text: text}) do
    "<span>" <> text <> "</span>"
  end
end
