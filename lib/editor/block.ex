defmodule Editor.Block do
  defstruct [:id, :type, :cells]

  @type id :: Editor.Utils.id()
  @type t :: %__MODULE__{cells: []}

  def new do
    %__MODULE__{
      id: Editor.Utils.new_id(),
      type: "p",
      cells: [Editor.Cell.new()]
    }
  end

  def split(%__MODULE__{cells: cells} = block, cell_id, index) do
    # split the call we are currently in
    cell_index = Enum.find_index(cells, &(&1.id === cell_id))
    cell = Enum.at(cells, cell_index)
    {cell_before, cell_after} = Editor.Cell.split(cell, index)

    # split other cells into two groups. first stays in current block, second
    # goes in new block
    {cells_before, cells_after} = Enum.split(cells, cell_index + 1)

    # current block gets cells before cursor, and part of current cell before
    # cursor
    cells_before = List.replace_at(cells_before, -1, cell_before)

    # new block gets part of current cell after cursor and other cells after
    # cursor
    block_before = %{block | cells: cells_before}

    cells_after = [cell_after | cells_after]
    block_after = %{new() | cells: cells_after}

    [block_before, block_after]
  end

  @spec update(t, id, String.t()) :: t
  def update(block, cell_id, value) do
    block
    |> update_cell(cell_id, value)
    |> resolve_transform()
  end

  defp update_cell(%Editor.Block{cells: cells} = block, cell_id, value) do
    cell_index = Enum.find_index(cells, &(&1.id === cell_id))
    cells = List.update_at(cells, cell_index, &%{&1 | content: value})
    %{block | cells: cells}
  end

  @spec resolve_transform(t) :: t
  defp resolve_transform(%__MODULE__{} = block) do
    case Enum.at(block.cells, 0) do
      %{content: "# " <> rest} -> block |> set_type("h1") |> set_cell(0, rest)
      %{content: "#&nbsp;" <> rest} -> block |> set_type("h1") |> set_cell(0, rest)
      %{content: "## " <> rest} -> block |> set_type("h2") |> set_cell(0, rest)
      %{content: "##&nbsp;" <> rest} -> block |> set_type("h2") |> set_cell(0, rest)
      %{content: "### " <> rest} -> block |> set_type("h3") |> set_cell(0, rest)
      %{content: "###&nbsp;" <> rest} -> block |> set_type("h3") |> set_cell(0, rest)
      %{content: "```" <> rest} -> block |> set_type("pre") |> set_cell(0, rest)
      %{} -> block
    end
  end

  defp set_type(%__MODULE__{} = block, type) do
    %{block | type: type}
  end

  defp set_cell(%__MODULE__{} = block, index, content) do
    cell = Enum.at(block.cells, index)
    cells = List.replace_at(block.cells, index, %{cell | content: content})
    %{block | cells: cells}
  end

  @spec downgrade_block(t) :: t
  def downgrade_block(%{type: "h1"} = block), do: %{block | type: "h2"}
  def downgrade_block(%{type: "h2"} = block), do: %{block | type: "h3"}
  def downgrade_block(%{type: "h3"} = block), do: %{block | type: "p"}
  def downgrade_block(%{type: "pre"} = block), do: %{block | type: "p"}
  def downgrade_block(%{} = block), do: block
end
