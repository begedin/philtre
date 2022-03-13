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

  @spec serialize(struct) :: map
  def serialize(%Block.P{id: id, pre_caret: pre_caret, post_caret: post_caret}) do
    %{"id" => id, "type" => "p", "content" => pre_caret <> post_caret}
  end

  def serialize(%Block.Blockquote{id: id, pre_caret: pre_caret, post_caret: post_caret}) do
    %{"id" => id, "type" => "blockquote", "content" => pre_caret <> post_caret}
  end

  def serialize(%Block.H1{id: id, pre_caret: pre_caret, post_caret: post_caret}) do
    %{"id" => id, "type" => "h1", "content" => pre_caret <> post_caret}
  end

  def serialize(%Block.H2{id: id, pre_caret: pre_caret, post_caret: post_caret}) do
    %{"id" => id, "type" => "h2", "content" => pre_caret <> post_caret}
  end

  def serialize(%Block.H3{id: id, pre_caret: pre_caret, post_caret: post_caret}) do
    %{"id" => id, "type" => "h3", "content" => pre_caret <> post_caret}
  end

  def serialize(%Block.Li{id: id, pre_caret: pre_caret, post_caret: post_caret}) do
    %{"id" => id, "type" => "li", "content" => pre_caret <> post_caret}
  end

  def serialize(%Block.Pre{id: id, pre_caret: pre_caret, post_caret: post_caret}) do
    %{"id" => id, "type" => "pre", "content" => pre_caret <> post_caret}
  end

  def normalize(%{"id" => id, "blocks" => blocks}) when is_binary(id) and is_list(blocks) do
    %Editor{id: id, blocks: Enum.map(blocks, &normalize/1)}
  end

  def normalize(%{"blocks" => blocks} = params) when is_list(blocks) do
    params |> Map.put("id", Editor.Utils.new_id()) |> normalize()
  end

  def normalize(%{"id" => id, "type" => "p", "content" => content}) do
    %Block.P{id: id, pre_caret: content, post_caret: ""}
  end

  def normalize(%{"id" => id, "type" => "blockquote", "content" => content}) do
    %Block.Blockquote{id: id, pre_caret: content, post_caret: ""}
  end

  def normalize(%{"id" => id, "type" => "h1", "content" => content}) do
    %Block.H1{id: id, pre_caret: content, post_caret: ""}
  end

  def normalize(%{"id" => id, "type" => "h2", "content" => content}) do
    %Block.H2{id: id, pre_caret: content, post_caret: ""}
  end

  def normalize(%{"id" => id, "type" => "h3", "content" => content}) do
    %Block.H3{id: id, pre_caret: content, post_caret: ""}
  end

  def normalize(%{"id" => id, "type" => "li", "content" => content}) do
    %Block.Li{id: id, pre_caret: content, post_caret: ""}
  end

  def normalize(%{"id" => id, "type" => "pre", "content" => content}) do
    %Block.Pre{id: id, pre_caret: content, post_caret: ""}
  end

  def text(%Editor{} = editor) do
    Enum.map_join(editor.blocks, "", &text/1)
  end

  def text(%_{pre_caret: _, post_caret: _} = block) do
    block |> html |> Floki.parse_document!() |> Floki.text()
  end

  def html(%type{pre_caret: pre_caret, post_caret: post_caret}) do
    tag = tag(type)
    "<#{tag}>" <> pre_caret <> post_caret <> "</#{tag}>"
  end

  def tag(Block.Blockquote), do: "p"
  def tag(Block.H1), do: "h1"
  def tag(Block.H2), do: "h2"
  def tag(Block.H3), do: "h3"
  def tag(Block.Li), do: "li"
  def tag(Block.P), do: "p"
  def tag(Block.Pre), do: "pre"
end
