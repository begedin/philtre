defmodule Editor.Engine do
  @moduledoc """
  Holds shared logic for modifying editor blocks
  """
  alias Editor.Block
  alias Editor.Utils

  @doc """
  Performs action of updating a block within an editor, which is the result of
  a user typing something into the block.
  """
  def update_block(%Editor{} = editor, %Block{} = block, %{pre: pre, post: post}) do
    index = Enum.find_index(editor.blocks, &(&1.id === block.id))

    if index >= 0 do
      pre = cleanup(pre)
      post = cleanup(post)
      new_block = resolve_transform(%{block | pre_caret: pre, post_caret: post, active: true})
      new_blocks = List.replace_at(editor.blocks, index, new_block)

      %{editor | blocks: new_blocks}
    else
      editor
    end
  end

  @doc """
  Performs action of spliting a block like into two lines, where both stay part of the same block.

  This is the result of the user usually hitting Shift + Enter.
  """
  def split_line(%Editor{} = editor, %Block{type: type} = block, %{pre: pre, post: post})
      when type in ["p", "pre", "blockquote"] do
    index = Enum.find_index(editor.blocks, &(&1.id === block.id))

    if index >= 0 do
      pre = cleanup(pre) <> "<br/>"
      post = cleanup(post)

      new_block = resolve_transform(%{block | pre_caret: pre, post_caret: post, active: true})
      new_blocks = List.replace_at(editor.blocks, index, new_block)

      %{editor | blocks: new_blocks}
    else
      editor
    end
  end

  def split_line(%Editor{} = editor, %Block{}), do: editor

  @doc """
  Performs action of splitting a block into two separate blocks at current cursor position.

  This is the result of a user hitting Enter.

  The first block retains the type of the original.
  The second block is usually a P block.
  """
  def split_block(%Editor{} = editor, %_{} = block, %{pre: pre, post: post}) do
    index = Enum.find_index(editor.blocks, &(&1.id === block.id))

    if index >= 0 do
      old_block = %{block | active: false, pre_caret: pre, post_caret: ""}

      new_type = if block.type == "li", do: "li", else: "p"

      new_block = %Block{
        active: true,
        id: Utils.new_id(),
        post_caret: post,
        pre_caret: "",
        type: new_type
      }

      new_blocks =
        editor.blocks |> List.replace_at(index, [old_block, new_block]) |> List.flatten()

      %{editor | blocks: new_blocks}
    else
      editor
    end
  end

  @doc """
  Splits block into two at cursor, then pastes in the current
  cliboard contents of the editor, between the two.
  """
  def paste(%Editor{clipboard: nil} = editor, %Block{} = _block, %{pre_caret: _, post_caret: _}) do
    editor
  end

  def paste(%Editor{} = editor, %Block{} = block, %{pre: pre, post: post}) do
    index = Enum.find_index(editor.blocks, &(&1.id === block.id))

    if index >= 0 do
      pre = cleanup(pre)
      post = cleanup(post)

      old_block = %{block | active: false, pre_caret: pre, post_caret: ""}

      replace_blocks =
        if post == "" do
          [old_block] ++ editor.clipboard
        else
          new_block = %Block{
            active: true,
            id: Utils.new_id(),
            post_caret: post,
            pre_caret: "",
            type: "p"
          }

          [old_block] ++ editor.clipboard ++ [new_block]
        end

      new_blocks =
        editor.blocks
        |> List.replace_at(index, replace_blocks)
        |> List.flatten()

      %{editor | blocks: new_blocks}
    else
      editor
    end
  end

  def backspace_from_start(%Editor{} = editor, %Block{type: "p"} = block) do
    merge_previous(editor, block)
  end

  def backspace_from_start(%Editor{} = editor, %Block{type: "h1"} = block) do
    convert(editor, block, "h2")
  end

  def backspace_from_start(%Editor{} = editor, %Block{type: "h2"} = block) do
    convert(editor, block, "h3")
  end

  def backspace_from_start(%Editor{} = editor, %Block{} = block) do
    convert(editor, block, "p")
  end

  defp convert(%Editor{} = editor, %Block{} = block, type)
       when type in ["p", "h1", "h2", "h3"] do
    index = Enum.find_index(editor.blocks, &(&1.id === block.id))

    if index >= 0 do
      new_block = %{block | type: type}
      new_blocks = List.replace_at(editor.blocks, index, new_block)
      %{editor | blocks: new_blocks}
    else
      editor
    end
  end

  defp merge_previous(%Editor{} = editor, %_{} = block) do
    index = Enum.find_index(editor.blocks, &(&1 == block)) - 1

    if index >= 0 do
      %_{} = previous_block = Enum.at(editor.blocks, index)
      merged = %{merge_second_into_first(previous_block, block) | id: Utils.new_id()}
      blocks = editor.blocks |> List.delete_at(index + 1) |> List.replace_at(index, merged)
      %{editor | blocks: blocks}
    else
      editor
    end
  end

  defp merge_second_into_first(%Block{} = first_block, %Block{} = other_block) do
    %{
      first_block
      | active: true,
        pre_caret: first_block.pre_caret <> first_block.post_caret,
        post_caret: other_block.pre_caret <> other_block.post_caret
    }
  end

  defp cleanup(content) do
    content
    |> String.replace("&nbsp;", " ", global: true)
    |> String.replace("&gt;", ">", global: true)
  end

  defp resolve_transform(%Block{type: "p"} = p) do
    case transform_type(p.pre_caret) do
      nil -> p
      other -> transform(p, other)
    end
  end

  defp resolve_transform(%Block{} = block), do: block

  defp transform_type("# " <> _), do: "h1"
  defp transform_type("## " <> _), do: "h2"
  defp transform_type("### " <> _), do: "h3"
  defp transform_type("* " <> _), do: "li"
  defp transform_type("```" <> _), do: "pre"
  defp transform_type("> " <> _), do: "blockquote"
  defp transform_type(_), do: nil

  defp transform(%Block{} = self, "h1") do
    %{self | type: "h1", pre_caret: String.replace(self.pre_caret, "# ", "")}
  end

  defp transform(%Block{} = self, "h2") do
    %{self | type: "h2", pre_caret: String.replace(self.pre_caret, "## ", "")}
  end

  defp transform(%Block{} = self, "h3") do
    %{self | type: "h3", pre_caret: String.replace(self.pre_caret, "### ", "")}
  end

  defp transform(%Block{} = self, "pre") do
    %{self | type: "pre", pre_caret: String.replace(self.pre_caret, "```", "")}
  end

  defp transform(%Block{} = self, "blockquote") do
    %{self | type: "blockquote", pre_caret: String.replace(self.pre_caret, "> ", "")}
  end

  defp transform(%Block{} = self, "li") do
    %{self | type: "li", pre_caret: String.replace(self.pre_caret, "* ", "")}
  end
end
