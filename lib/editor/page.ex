defmodule Editor.Page do
  defstruct blocks: []

  @type t :: %__MODULE__{}
  @type id :: Editor.Utils.id()
  @type block :: Editor.Block.t()

  @spec new :: t
  def new do
    %__MODULE__{
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

    blocks =
      blocks
      |> List.replace_at(current_block_index, Editor.Block.split(current_block, cell_id, index))
      |> List.flatten()

    %{page | blocks: blocks}
  end

  @spec update_block(t, block_id :: id, cell_id :: id, String.t()) :: t
  def update_block(%__MODULE__{blocks: blocks} = page, block_id, cell_id, value) do
    block_index = Enum.find_index(blocks, &(&1.id === block_id))

    block =
      blocks
      |> Enum.at(block_index)
      |> Editor.Block.update(cell_id, value)

    blocks = List.replace_at(blocks, block_index, block)

    %{page | blocks: blocks}
  end

  @spec downgrade_block(t, block_id :: id, cell_id :: id) :: t
  def downgrade_block(%__MODULE__{blocks: blocks} = page, block_id, cell_id) do
    block_index = Enum.find_index(blocks, &(&1.id === block_id))
    block = Enum.at(blocks, block_index)
    previous_block = Enum.at(blocks, block_index - 1)

    cell_index = Enum.find_index(block.cells, &(&1.id === cell_id))

    blocks =
      cond do
        cell_index !== 0 ->
          blocks

        block_index === 0 ->
          blocks

        block.type !== "p" ->
          List.update_at(blocks, block_index, &Editor.Block.downgrade_block(&1))

        block.type === "p" ->
          blocks
          |> List.delete_at(block_index)
          |> List.replace_at(block_index - 1, %{
            previous_block
            | cells: previous_block.cells ++ block.cells
          })
      end

    %{page | blocks: blocks}
  end
end
