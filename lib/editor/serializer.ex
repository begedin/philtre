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
  def serialize(%Block{id: id, type: type, pre_caret: pre_caret, post_caret: post_caret})
      when type in @types do
    %{"id" => id, "type" => type, "content" => pre_caret <> post_caret}
  end

  def normalize(%{"id" => id, "blocks" => blocks}) when is_binary(id) and is_list(blocks) do
    %Editor{id: id, blocks: Enum.map(blocks, &normalize/1)}
  end

  def normalize(%{"blocks" => blocks} = params) when is_list(blocks) do
    params |> Map.put("id", Editor.Utils.new_id()) |> normalize()
  end

  def normalize(%{"id" => id, "type" => type, "content" => content}) when type in @types do
    %Block{id: id, type: type, pre_caret: content, post_caret: ""}
  end

  def text(%Editor{} = editor) do
    Enum.map_join(editor.blocks, "", &text/1)
  end

  def text(%Block{pre_caret: _, post_caret: _} = block) do
    block |> html |> Floki.parse_document!() |> Floki.text()
  end

  def html(%Block{pre_caret: pre_caret, post_caret: post_caret, type: tag}) do
    "<#{tag}>" <> pre_caret <> post_caret <> "</#{tag}>"
  end
end
