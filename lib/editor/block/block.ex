defmodule Editor.Block do
  @moduledoc """
  Represents a mid-tier element of a page. Contains multiple cells and is usually
  a self-contained section. For example, a title, a paragraph or a list.
  """

  alias Editor.Block
  alias Editor.Cell
  alias Editor.SplitResult
  alias Editor.Utils

  defstruct id: nil, type: nil, cells: []

  @type id :: Utils.id()
  @type t :: %__MODULE__{}

  @spec new(String.t()) :: t
  def new(type \\ "p")

  def new(type) do
    %__MODULE__{
      cells: [Cell.new()],
      id: Utils.new_id(),
      type: type
    }
  end

  @doc """
  Updates content of specified cell in specified block with the new value.
  """
  @spec update(t, id, String.t()) :: t
  def update(%__MODULE__{cells: cells} = block, cell_id, value) do
    cell_index = Enum.find_index(cells, &(&1.id === cell_id))
    new_cells = List.update_at(cells, cell_index, &%{&1 | content: value})
    %{block | cells: new_cells}
  end

  @doc """
  If the first cell of the specified block contains markdown-like wildcard strings, transforms
  the block to a new type.

  ## Transforms

  - `#` becomes an `"h1"`
  - `##` becomes an `"h2"`
  - `###` becomes an `"h3"`
  - ````` becomes a `"pre"`
  - `* ` becomes an `"ul"`

  """
  @spec resolve_transform(t) :: t
  def resolve_transform(%__MODULE__{cells: [%{content: "# " <> _} | _]} = block) do
    transform(block, "h1")
  end

  def resolve_transform(%__MODULE__{cells: [%{content: "#&nbsp;" <> _} | _]} = block) do
    transform(block, "h1")
  end

  def resolve_transform(%__MODULE__{cells: [%{content: "## " <> _} | _]} = block) do
    transform(block, "h2")
  end

  def resolve_transform(%__MODULE__{cells: [%{content: "##&nbsp;" <> _} | _]} = block) do
    transform(block, "h2")
  end

  def resolve_transform(%__MODULE__{cells: [%{content: "### " <> _} | _]} = block) do
    transform(block, "h3")
  end

  def resolve_transform(%__MODULE__{cells: [%{content: "###&nbsp;" <> _} | _]} = block) do
    transform(block, "h3")
  end

  def resolve_transform(%__MODULE__{cells: [%{content: "```" <> _} | _]} = block) do
    transform(block, "pre")
  end

  def resolve_transform(%__MODULE__{cells: [%{content: "* " <> _} | _]} = block) do
    transform(block, "ul")
  end

  def resolve_transform(%__MODULE__{cells: [%{content: "*&nbsp;" <> _} | _]} = block) do
    transform(block, "ul")
  end

  def resolve_transform(%__MODULE__{cells: [%{content: "&gt; " <> _} | _]} = block) do
    transform(block, "blockquote")
  end

  def resolve_transform(%__MODULE__{cells: [%{content: "&gt;&nbsp;" <> _} | _]} = block) do
    transform(block, "blockquote")
  end

  def resolve_transform(%__MODULE__{} = block), do: block

  @spec transform(t, String.t()) :: t
  defp transform(%__MODULE__{cells: [cell | rest]} = block, "ul") do
    cells = Enum.map([Cell.trim(cell) | rest], &Cell.transform(&1, "li"))
    %{block | type: "ul", cells: cells}
  end

  defp transform(%__MODULE__{cells: [cell | rest]} = block, type) do
    cells = [Cell.trim(cell) | rest]
    %{block | type: type, cells: cells}
  end

  @doc """
  Peforms a backspace operation on a block.

  The backspace operation has a different outcome depending on the block type and cursor position.

  A "p" block, backspaced from the 0th cell gets removed

  Any other block backspaced from the 0th cell get's downgraded

    - "h1" to "h2"
    - "h2" to "h3"
    - any other block to "p"

  Backspace from a non-0th cell will perform the backspace operation on the cell itself, which
  can result in one of

  - deletion of the cell
  - join of the cell with the previous cell

  """
  @spec backspace(t, id) :: [] | [t]
  def backspace(%__MODULE__{cells: cells, type: type} = block, cell_id) do
    cell_index = Enum.find_index(cells, &(&1.id === cell_id))

    cond do
      cell_index === 0 and type === "p" ->
        []

      cell_index === 0 ->
        [block |> downgrade() |> downgrade_cells()]

      cell_index > 0 ->
        action = cells |> Enum.at(cell_index) |> Cell.backspace()

        new_cells =
          case action do
            :delete -> List.delete_at(cells, cell_index)
            :join_to_previous -> join_cells(block, cell_index, cell_index - 1)
          end

        [%{block | cells: new_cells}]
    end
  end

  @spec join_cells(t, integer, integer) :: list(Cell.t())
  defp join_cells(%__MODULE__{cells: cells}, from_index, to_index)
       when from_index < 0 or to_index < 0 do
    cells
  end

  defp join_cells(%__MODULE__{cells: cells}, from_index, to_index) do
    from_cell = Enum.at(cells, from_index)
    to_cell = Enum.at(cells, to_index)
    cell = Cell.join(to_cell, from_cell)

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
    %{block | cells: Enum.map(cells, &Cell.transform(&1, "span"))}
  end

  @doc """
  Joins the content of the first block into the second
  """
  @spec join(t, t) :: t
  def join(%__MODULE__{} = from, %__MODULE__{} = to) do
    %{to | cells: to.cells ++ from.cells}
  end

  @doc """
  Clones the given block by cloning it's cells and giving it a new id
  """
  @spec clone(t) :: t
  def clone(%__MODULE__{} = block) do
    %{block | id: Utils.new_id(), cells: Enum.map(block.cells, &Cell.clone/1)}
  end

  @doc """
  Performs basic newline operation.

  This operation will always effectively split the entire page at the target
  index of the target cell.

  The cell will be split in two. The block containing it will also be split in two. The first part
  of the split cell, as well as the cells preceding it will go to the first block. The second part
  of the cell and the cells following it will go to the second block.
  """
  @spec newline(Block.t(), Cell.t(), integer) :: SplitResult.t()
  def newline(%Block{} = block, %Cell{} = cell, index) do
    {cells_before, cells_after} = split_around_cell(block.cells, cell)
    {cell_before, cell_after} = split_cell(cell, index)

    %Cell{id: active_cell_id} = cell_after

    new_blocks = [
      %Block{block | cells: cells_before ++ [cell_before]},
      %Block{Block.new("p") | cells: [cell_after] ++ cells_after}
    ]

    %SplitResult{
      active_cell_id: active_cell_id,
      cursor_index: 0,
      new_blocks: new_blocks
    }
  end

  def backspace(%Editor{} = editor, %Block{} = block, %Cell{} = cell) do
    # merge two cells within a block
    cell_index = Enum.find_index(block.cells, &(&1 === cell))
    previous_cell_index = cell_index - 1
    %Cell{} = previous_cell = Enum.at(block.cells, previous_cell_index)
    %Cell{} = merged_cell = Cell.join(cell, previous_cell)

    new_cells =
      block.cells
      |> List.delete_at(cell_index)
      |> List.replace_at(previous_cell_index, merged_cell)

    %Block{} = new_block = %{block | cells: new_cells}
    block_index = Enum.find_index(editor.blocks, &(&1 === block))
    new_blocks = List.replace_at(editor.blocks, block_index, new_block)

    %{
      editor
      | blocks: new_blocks
    }
  end

  def downgrade(%Editor{} = editor, %Block{} = block, type \\ "p") do
    block_index = Enum.find_index(editor.blocks, &(&1 === block))
    %{editor | blocks: List.replace_at(editor.blocks, block_index, %{block | type: type})}
  end

  @doc """
  Splits a list of cells around the specified cell.

  Returns a tuple of to lists of cells. The left
  list contains cells preceeding the specified cell, the right the ones following it.

  The specified cell is excluded from the results.
  """
  @spec split_around_cell(list(Cell.t()), Cell.t()) :: {list(Cell.t()), list(Cell.t())}
  def split_around_cell(cells, %Cell{} = cell) do
    cell_index = Enum.find_index(cells, &(&1.id === cell.id))
    cells |> Enum.reject(&(&1 === cell)) |> Enum.split(cell_index)
  end

  @doc """
  Splits the specified cell into two cells at the target index
  """
  @spec split_cell(Cell.t(), integer) :: {Cell.t(), Cell.t()}
  def split_cell(%Cell{} = cell, index) do
    {content_before, content_after} = String.split_at(cell.content, index)
    {Cell.new(cell.type, content_before), Cell.new(cell.type, content_after)}
  end
end
