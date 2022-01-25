defmodule Editor.Operations do
  @moduledoc """
  Represents the entire content of a single record written in an editor.
  """

  alias Editor.Block
  alias Editor.Cell
  alias Editor.SplitResult
  alias Editor.Utils

  @type id :: Utils.id()
  @type block :: Block.t()

  @spec newline(Editor.t(), cell_id :: id, integer) :: Editor.t()
  def newline(%Editor{blocks: blocks} = editor, cell_id, index) do
    %Block{} = block = find_block_by_cell_id(blocks, cell_id)
    %Cell{} = cell = Enum.find(block.cells, &(&1.id === cell_id))

    %SplitResult{} =
      result =
      case block.type do
        "h1" -> Block.H1.newline(block, cell, index)
        "h2" -> Block.H2.newline(block, cell, index)
        "h3" -> Block.H3.newline(block, cell, index)
        "p" -> Block.P.newline(block, cell, index)
        "pre" -> Block.Pre.newline(block, cell, index)
        "ul" -> Block.Ul.newline(block, cell, index)
      end

    block_index = Enum.find_index(blocks, &(&1 == block))

    {blocks_before, blocks_after} =
      blocks |> Enum.reject(&(&1 == block)) |> Enum.split(block_index)

    %{
      editor
      | blocks: blocks_before ++ result.new_blocks ++ blocks_after,
        active_cell_id: result.active_cell_id,
        cursor_index: result.cursor_index
    }
  end

  @spec update_block(Editor.t(), cell_id :: id, String.t()) :: Editor.t()
  def update_block(%Editor{blocks: blocks} = editor, cell_id, value) do
    %Block{} = old_block = find_block_by_cell_id(blocks, cell_id)
    block_index = Enum.find_index(blocks, &(&1.id === old_block.id))

    %Block{} = new_block = old_block |> Block.update(cell_id, value) |> Block.resolve_transform()
    blocks = List.replace_at(blocks, block_index, new_block)

    %Cell{} = cell = Enum.find(new_block.cells, &(&1.id === cell_id))

    cursor_index =
      if old_block.type != new_block.type do
        String.length(cell.content)
      else
        nil
      end

    %{editor | blocks: blocks, active_cell_id: cell_id, cursor_index: cursor_index}
  end

  @spec backspace(Editor.t(), cell_id :: id) :: Editor.t()
  def backspace(%Editor{blocks: blocks} = editor, cell_id) do
    %Editor.Block{} = block = find_block_by_cell_id(blocks, cell_id)
    %Editor.Cell{} = cell = Enum.find(block.cells, &(&1.id === cell_id))

    case block.type do
      "p" -> Block.P.backspace(editor, block, cell)
      "h1" -> Block.H1.backspace(editor, block, cell)
      "h2" -> Block.H2.backspace(editor, block, cell)
      "h3" -> Block.H3.backspace(editor, block, cell)
      "ul" -> Block.Ul.backspace(editor, block, cell)
      "pre" -> Block.Pre.backspace(editor, block, cell)
    end
  end

  @spec paste_blocks(Editor.t(), list(Block.t()), cell_id :: id, integer) :: Editor.t()
  def paste_blocks(%Editor{} = editor, blocks, cell_id, index)
      when is_list(blocks) and is_binary(cell_id) and is_integer(index) do
    %Block{} = current_block = find_block_by_cell_id(editor.blocks, cell_id)

    current_block_index = Enum.find_index(editor.blocks, &(&1 === current_block))

    clones = Enum.map(blocks, &Block.clone/1)

    %Cell{} = cell = Enum.find(current_block.cells, &(&1.id === cell_id))

    %SplitResult{
      new_blocks: [part_before, part_after]
    } = Editor.Block.Base.newline(current_block, cell, index)

    new_blocks = [part_before] ++ clones ++ [part_after]

    all_blocks =
      editor.blocks |> List.replace_at(current_block_index, new_blocks) |> List.flatten()

    active_cell = Enum.at(part_after.cells, 0)

    %{editor | blocks: all_blocks, active_cell_id: active_cell.id, cursor_index: 0}
  end

  @spec find_block_by_cell_id(list(Block.t()), cell_id :: id) :: Block.t() | nil
  defp find_block_by_cell_id(blocks, cell_id) when is_list(blocks) and is_binary(cell_id) do
    Enum.find(blocks, fn %Block{} = block ->
      Enum.any?(block.cells, &(&1.id === cell_id))
    end)
  end
end
