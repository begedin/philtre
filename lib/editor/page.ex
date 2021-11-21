defmodule Editor.Page do
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

  @spec insert_block(t, block_id :: id, cell_id :: id, integer) :: t
  def insert_block(%__MODULE__{blocks: blocks} = page, block_id, cell_id, index) do
    current_block_index = Enum.find_index(blocks, &(&1.id === block_id))
    current_block = Enum.at(blocks, current_block_index)

    case Editor.Block.split(current_block, cell_id, index) do
      [%{} = block] ->
        blocks = List.replace_at(blocks, current_block_index, block)
        %{page | blocks: blocks, active_cell_id: nil, cursor_index: nil}

      [_, new_block] = new_blocks ->
        blocks = blocks |> List.replace_at(current_block_index, new_blocks) |> List.flatten()
        active_cell = Enum.at(new_block.cells, 0)
        %{page | blocks: blocks, active_cell_id: active_cell.id, cursor_index: 0}
    end
  end

  @spec update_block(t, block_id :: id, cell_id :: id, String.t()) :: t
  def update_block(%__MODULE__{blocks: blocks} = page, block_id, cell_id, value) do
    block_index = Enum.find_index(blocks, &(&1.id === block_id))

    block =
      blocks
      |> Enum.at(block_index)
      |> Editor.Block.update(cell_id, value)

    blocks = List.replace_at(blocks, block_index, block)

    %{page | blocks: blocks, active_cell_id: cell_id, cursor_index: nil}
  end

  @spec backspace(t, block_id :: id, cell_id :: id) :: t
  def backspace(%__MODULE__{blocks: blocks} = page, block_id, cell_id) do
    block_index = Enum.find_index(blocks, &(&1.id === block_id))
    %Editor.Block{type: old_type, cells: old_cells} = block = Enum.at(blocks, block_index)

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
end
