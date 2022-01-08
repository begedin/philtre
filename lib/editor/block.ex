defmodule Editor.Block do
  defstruct id: nil, type: nil, cells: []

  @type id :: Editor.Utils.id()
  @type t :: %__MODULE__{cells: []}

  def new do
    %__MODULE__{
      cells: [Editor.Cell.new()],
      id: Editor.Utils.new_id(),
      type: "p"
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
    cells_after = [cell_after | cells_after]

    if block.type in ["ul"] do
      [%{block | cells: cells_before ++ cells_after}]
    else
      # new block gets part of current cell after cursor and other cells after
      # cursor
      block_before = %{block | cells: cells_before}

      block_after = %{new() | cells: cells_after}

      [block_before, block_after]
    end
  end

  def hard_split(%__MODULE__{cells: cells} = block, cell_id, index) do
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
    cells_after = [cell_after | cells_after]

    # new block gets part of current cell after cursor and other cells after
    # cursor
    block_before = %{block | cells: cells_before}

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
  defp resolve_transform(%__MODULE__{cells: [first_cell | _]} = block) do
    case first_cell.content do
      "# " <> _ -> transform(block, "h1")
      "#&nbsp;" <> _ -> transform(block, "h1")
      "## " <> _ -> transform(block, "h2")
      "##&nbsp;" <> _ -> transform(block, "h2")
      "### " <> _ -> transform(block, "h3")
      "###&nbsp;" <> _ -> transform(block, "h3")
      "```" <> _ -> transform(block, "pre")
      "* " <> _ -> transform(block, "ul")
      "*&nbsp;" <> _ -> transform(block, "ul")
      _ -> block
    end
  end

  defp transform(%__MODULE__{cells: [cell | rest]} = block, "ul") do
    cells = Enum.map([Editor.Cell.trim(cell) | rest], &Editor.Cell.transform(&1, "li"))
    %{block | type: "ul", cells: cells}
  end

  defp transform(%__MODULE__{cells: [cell | rest]} = block, type) do
    cells = [Editor.Cell.trim(cell) | rest]
    %{block | type: type, cells: cells}
  end

  def backspace(%__MODULE__{cells: cells, type: type} = block, cell_id) do
    cell_index = Enum.find_index(cells, &(&1.id === cell_id))

    cond do
      cell_index === 0 and type === "p" ->
        []

      cell_index === 0 ->
        [block |> downgrade() |> downgrade_cells()]

      cell_index > 0 ->
        action = cells |> Enum.at(cell_index) |> Editor.Cell.backspace()

        new_cells =
          case action do
            :delete -> List.delete_at(cells, cell_index)
            :join_to_previous -> join_cells(block, cell_index, cell_index - 1)
          end

        [%{block | cells: new_cells}]
    end
  end

  defp join_cells(%__MODULE__{} = block, from_index, to_index)
       when from_index < 0 or to_index < 0 do
    block
  end

  defp join_cells(%__MODULE__{cells: cells}, from_index, to_index) do
    from_cell = Enum.at(cells, from_index)
    to_cell = Enum.at(cells, to_index)
    cell = Editor.Cell.join(to_cell, from_cell)

    cells
    |> List.delete_at(from_index)
    |> List.replace_at(to_index, cell)
  end

  @spec downgrade(t) :: t
  defp downgrade(%{type: "h1"} = block), do: %{block | type: "h2"}
  defp downgrade(%{type: "h2"} = block), do: %{block | type: "h3"}
  defp downgrade(%{type: "h3"} = block), do: %{block | type: "p"}
  defp downgrade(%{type: "pre"} = block), do: %{block | type: "p"}
  defp downgrade(%{type: "ul"} = block), do: %{block | type: "p"}
  defp downgrade(%{} = block), do: block

  @spec downgrade_cells(t) :: t
  defp downgrade_cells(%{cells: cells} = block) do
    %{block | cells: Enum.map(cells, &Editor.Cell.downgrade/1)}
  end

  def clone(%__MODULE__{} = block) do
    %{block | id: Editor.Utils.new_id(), cells: Enum.map(block.cells, &Editor.Cell.clone/1)}
  end
end
