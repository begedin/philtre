defmodule Editor.Page do
  defstruct blocks: []

  @type t :: %__MODULE__{}
  @type id :: Ecto.UUID.t()
  @type block :: Editor.Block.t()

  @spec new :: t
  def new do
    %__MODULE__{
      blocks: [
        %Editor.Block{
          type: "h1",
          id: new_id(),
          content: "This is the title of your page"
        }
      ]
    }
  end

  @spec add_block_after(t, id) :: t
  def add_block_after(%__MODULE__{blocks: blocks} = page, id) do
    index = Enum.find_index(blocks, &(&1.id === id)) + 1

    blocks =
      List.insert_at(blocks, index, %Editor.Block{
        id: new_id(),
        type: "p",
        content: ""
      })

    %{page | blocks: blocks}
  end

  @spec update_block(t, id, String.t()) :: t
  def update_block(%__MODULE__{blocks: blocks} = page, id, value) do
    index = Enum.find_index(blocks, &(&1.id === id))
    blocks = List.update_at(blocks, index, &Editor.Block.update_content(&1, value))

    %{page | blocks: blocks}
  end

  @spec downgrade_block(t, id) :: t
  def downgrade_block(%__MODULE__{blocks: blocks} = page, id) do
    index = Enum.find_index(blocks, &(&1.id === id))
    block = Enum.at(blocks, index)

    blocks =
      cond do
        index === 0 -> blocks
        block.type === "p" -> List.delete_at(blocks, index)
        block.type !== "p" -> List.update_at(blocks, index, &Editor.Block.downgrade_block(&1))
      end

    %{page | blocks: blocks}
  end

  @spec new_id :: id
  defp new_id do
    Ecto.UUID.generate()
  end
end
