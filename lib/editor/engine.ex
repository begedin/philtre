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
  def update_block(%Editor{} = editor, %_{} = block, %{pre: pre, post: post}) do
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
  def split_line(%Editor{} = editor, %_{} = block, %{pre: pre, post: post}) do
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

      new_block = %Block.P{
        id: Utils.new_id(),
        active: true,
        pre_caret: "",
        post_caret: post
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
  def paste(%Editor{clipboard: nil} = editor, %_{} = _block, %{pre_caret: _, post_caret: _}) do
    editor
  end

  def paste(%Editor{} = editor, %_{} = block, %{pre: pre, post: post}) do
    index = Enum.find_index(editor.blocks, &(&1.id === block.id))

    if index >= 0 do
      pre = cleanup(pre)
      post = cleanup(post)

      old_block = %{block | active: false, pre_caret: pre, post_caret: ""}

      replace_blocks =
        if post == "" do
          [old_block] ++ editor.clipboard
        else
          new_block = %Block.P{
            id: Utils.new_id(),
            active: true,
            pre_caret: "",
            post_caret: post
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

  @doc """
  Replaces specified block with a new block of the specified type, with the same contents.
  """
  def convert(%Editor{} = editor, %_{} = block, type)
      when type in [Block.P, Block.H2, Block.H3] do
    index = Enum.find_index(editor.blocks, &(&1.id === block.id))

    if index >= 0 do
      new_block =
        Kernel.struct!(type, %{
          id: Utils.new_id(),
          active: block.active,
          pre_caret: block.pre_caret,
          post_caret: block.post_caret
        })

      new_blocks = List.replace_at(editor.blocks, index, new_block)
      %{editor | blocks: new_blocks}
    else
      editor
    end
  end

  @doc """
  Merges specified block into it's predecessor in the editor.
  """
  def merge_previous(%Editor{} = editor, %_{} = block) do
    index = Enum.find_index(editor.blocks, &(&1 == block)) - 1

    if index >= 0 do
      %_{} = previous_block = Enum.at(editor.blocks, index)
      merged = merge_second_into_first(previous_block, block)
      blocks = editor.blocks |> List.delete_at(index + 1) |> List.replace_at(index, merged)
      %{editor | blocks: blocks}
    else
      editor
    end
  end

  defp merge_second_into_first(%_{} = first_block, %Block.P{} = other_block) do
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

  defp resolve_transform(%Block.P{} = p) do
    case transform_type(p.pre_caret) do
      nil -> p
      other -> transform(p, other)
    end
  end

  defp resolve_transform(%_{} = block), do: block

  defp transform_type("# " <> _), do: Block.H1
  defp transform_type("## " <> _), do: Block.H2
  defp transform_type("### " <> _), do: Block.H3
  defp transform_type("* " <> _), do: Block.Li
  defp transform_type("```" <> _), do: Block.Pre
  defp transform_type("> " <> _), do: Block.Blockquote
  defp transform_type("&gt; " <> _), do: Block.Blockquote
  defp transform_type(_), do: nil

  defp transform(%Block.P{} = self, Block.H1) do
    %Block.H1{
      id: self.id,
      active: self.active,
      pre_caret: String.replace(self.pre_caret, "# ", ""),
      post_caret: self.post_caret
    }
  end

  defp transform(%Block.P{} = self, Block.H2) do
    %Block.H2{
      id: self.id,
      active: self.active,
      pre_caret: String.replace(self.pre_caret, "## ", ""),
      post_caret: self.post_caret
    }
  end

  defp transform(%Block.P{} = self, Block.H3) do
    %Block.H3{
      id: self.id,
      active: self.active,
      pre_caret: String.replace(self.pre_caret, "### ", ""),
      post_caret: self.post_caret
    }
  end

  defp transform(%Block.P{} = self, Block.Pre) do
    %Block.Pre{
      id: self.id,
      active: self.active,
      pre_caret: String.replace(self.pre_caret, "```", ""),
      post_caret: self.post_caret
    }
  end

  defp transform(%Block.P{} = self, Block.Blockquote) do
    %Block.Blockquote{
      id: self.id,
      active: self.active,
      pre_caret: String.replace(self.pre_caret, "> ", ""),
      post_caret: self.post_caret
    }
  end

  defp transform(%Block.P{} = self, Block.Li) do
    %Block.Li{
      id: self.id,
      active: self.active,
      pre_caret: String.replace(self.pre_caret, "* ", ""),
      post_caret: self.post_caret
    }
  end
end
