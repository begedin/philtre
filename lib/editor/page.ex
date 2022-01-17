defmodule Editor.Page do
  @moduledoc """
  Represents the entire content of a single record written in an editor.
  """
  defstruct blocks: [], active_cell_id: nil, cursor_index: nil

  @type t :: %__MODULE__{}
  @type id :: Editor.Utils.id()
  @type block :: Editor.Block.t()

  @spec new :: t
  def new do
    %__MODULE__{
      active_cell_id: nil,
      blocks: [
        %Editor.Block{
          type: "h1",
          id: Editor.Utils.new_id(),
          cells: [
            %Editor.Cell{
              id: Editor.Utils.new_id(),
              type: "span",
              content: "This is the title of your page"
            }
          ]
        }
      ]
    }
  end

  @spec insert_block(t, cell_id :: id, integer) :: t
  def insert_block(%__MODULE__{blocks: blocks} = page, cell_id, index) do
    %Editor.Block{} = current_block = find_block_by_cell_id(blocks, cell_id)
    current_block_index = Enum.find_index(blocks, &(&1 === current_block))

    case Editor.Block.split(current_block, cell_id, index) do
      [%Editor.Block{} = new_block] ->
        old_cell_ids = Enum.map(current_block.cells, & &1.id)
        new_cell_ids = Enum.map(new_block.cells, & &1.id)
        new_cell_id = Enum.find(new_cell_ids, &(&1 not in old_cell_ids))
        %Editor.Cell{} = new_cell = Enum.find(new_block.cells, &(&1.id === new_cell_id))
        active_cell_id = new_cell.id
        cursor_index = String.length(new_cell.content)
        blocks = List.replace_at(blocks, current_block_index, new_block)
        %{page | blocks: blocks, active_cell_id: active_cell_id, cursor_index: cursor_index}

      [_, %Editor.Block{} = new_block] = new_blocks ->
        blocks = blocks |> List.replace_at(current_block_index, new_blocks) |> List.flatten()
        active_cell = Enum.at(new_block.cells, 0)
        %{page | blocks: blocks, active_cell_id: active_cell.id, cursor_index: 0}
    end
  end

  @spec update_block(t, cell_id :: id, String.t()) :: t
  def update_block(%__MODULE__{blocks: blocks} = page, cell_id, value) do
    %Editor.Block{} = old_block = find_block_by_cell_id(blocks, cell_id)
    block_index = Enum.find_index(blocks, &(&1.id === old_block.id))

    %Editor.Block{} =
      new_block =
      old_block |> Editor.Block.update(cell_id, value) |> Editor.Block.resolve_transform()

    blocks = List.replace_at(blocks, block_index, new_block)

    %Editor.Cell{} = cell = Enum.find(new_block.cells, &(&1.id === cell_id))

    cursor_index =
      if old_block.type != new_block.type do
        String.length(cell.content)
      else
        nil
      end

    %{page | blocks: blocks, active_cell_id: cell_id, cursor_index: cursor_index}
  end

  @spec backspace(t, cell_id :: id) :: t
  def backspace(%__MODULE__{blocks: blocks} = page, cell_id) do
    %Editor.Block{type: old_type, cells: old_cells} =
      block = find_block_by_cell_id(blocks, cell_id)

    block_index = Enum.find_index(blocks, &(&1 === block))

    case Editor.Block.backspace(block, cell_id) do
      # block deletion
      [] ->
        blocks = List.delete_at(blocks, block_index)
        prev_block = Enum.at(blocks, block_index - 1)
        prev_cell = Enum.at(prev_block.cells, -1)

        %{
          page
          | blocks: blocks,
            active_cell_id: prev_cell.id,
            cursor_index: String.length(prev_cell.content)
        }

      # block downgrade
      [%{type: new_type} = downgraded_block] when new_type != old_type ->
        blocks = List.replace_at(blocks, block_index, downgraded_block)
        active_cell = Enum.at(block.cells, 0)

        %{
          page
          | blocks: blocks,
            active_cell_id: active_cell.id,
            cursor_index: 0
        }

      # cell merge
      [%{cells: cells} = smaller_block] when length(cells) < length(old_cells) ->
        blocks = List.replace_at(blocks, block_index, smaller_block)
        cell_index = Enum.find_index(old_cells, &(&1.id == cell_id)) - 1

        old_cell = Enum.at(old_cells, cell_index)
        active_cell = Enum.at(cells, cell_index)

        %{
          page
          | blocks: blocks,
            active_cell_id: active_cell.id,
            cursor_index: String.length(old_cell.content)
        }
    end
  end

  @spec paste_blocks(t, list(Editor.Block.t()), cell_id :: id, integer) :: t
  def paste_blocks(%__MODULE__{} = page, blocks, cell_id, index)
      when is_list(blocks) and is_binary(cell_id) and is_integer(index) do
    %Editor.Block{} = current_block = find_block_by_cell_id(page.blocks, cell_id)

    current_block_index = Enum.find_index(page.blocks, &(&1 === current_block))

    clones = Enum.map(blocks, &Editor.Block.clone/1)

    [part_before, part_after] = Editor.Block.hard_split(current_block, cell_id, index)

    new_blocks = [part_before] ++ clones ++ [part_after]
    all_blocks = page.blocks |> List.replace_at(current_block_index, new_blocks) |> List.flatten()
    active_cell = Enum.at(part_after.cells, 0)

    %{page | blocks: all_blocks, active_cell_id: active_cell.id, cursor_index: 0}
  end

  @spec find_block_by_cell_id(list(Editor.Block.t()), cell_id :: id) :: Editor.Block.t() | nil
  defp find_block_by_cell_id(blocks, cell_id) when is_list(blocks) and is_binary(cell_id) do
    Enum.find(blocks, fn %Editor.Block{} = block ->
      Enum.any?(block.cells, &(&1.id === cell_id))
    end)
  end
end
