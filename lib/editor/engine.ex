defmodule Editor.Engine do
  @moduledoc """
  Holds shared logic for modifying editor blocks
  """
  alias Editor.Block
  alias Editor.Utils

  @spec update(
          Editor.t(),
          Block.t(),
          %{required(:selection) => map, required(:cells) => list(map)}
        ) :: Editor.t()
  def update(%Editor{} = editor, %Block{} = block, %{selection: nil, cells: []}) do
    %Block.Cell{} = cell = Block.Cell.new()
    %Block{} = new_block = %{block | cells: [cell], selection: Block.Selection.new_start_of(cell)}
    replace_block(editor, block, [new_block])
  end

  def update(%Editor{} = editor, %Block{} = block, %{
        selection: %Block.Selection{
          start_id: start_id,
          end_id: end_id,
          start_offset: start_offset,
          end_offset: end_offset
        },
        cells: new_cells
      }) do
    old_cells = block.cells

    new_cells =
      Enum.map(new_cells, fn %{"id" => id, "modifiers" => modifiers, "text" => text} ->
        %Block.Cell{id: id, modifiers: modifiers, text: text}
      end)

    new_ids = Enum.map(new_cells, & &1.id)
    remaining_cells = Enum.filter(old_cells, &(&1.id in new_ids))

    updated_cells =
      Enum.map(remaining_cells, fn %Block.Cell{} = cell ->
        %Block.Cell{} = params = Enum.find(new_cells, &(&1.id === cell.id))
        %{cell | modifiers: params.modifiers, text: params.text}
      end)

    start_cell = Enum.find(remaining_cells, &(&1.id === start_id))
    end_cell = Enum.find(remaining_cells, &(&1.id === end_id))

    pre_cells =
      updated_cells
      |> Enum.split_with(&(&1.id === start_cell.id))
      |> Kernel.elem(0)

    post_cells =
      updated_cells
      |> Enum.split_with(&(&1.id === end_cell.id))
      |> Kernel.elem(1)

    new_block =
      resolve_transform(%{
        block
        | cells: pre_cells ++ post_cells,
          selection: %Block.Selection{
            start_id: start_id,
            end_id: end_id,
            start_offset: start_offset,
            end_offset: end_offset
          }
      })

    replace_block(editor, block, [new_block])
  end

  @spec toggle_style_on_selection(
          Editor.t(),
          Block.t(),
          %{
            required(:selection) => map,
            required(:style) => String.t()
          }
        ) :: Editor.t()
  def toggle_style_on_selection(%Editor{} = editor, %Block{} = block, %{
        selection: %Block.Selection{
          start_id: start_id,
          end_id: end_id,
          start_offset: start_offset,
          end_offset: end_offset
        },
        style: style
      }) do
    cells = block.cells
    start_cell_index = Enum.find_index(cells, &(&1.id === start_id))

    new_block =
      if start_id !== end_id do
        {cells_before, [start_cell | remaining_cells]} = Enum.split(cells, start_cell_index)

        end_cell_index = Enum.find_index(remaining_cells, &(&1.id === end_id))
        {cells_between, [end_cell | cells_after]} = Enum.split(remaining_cells, end_cell_index)

        {start_text_left, start_text_right} = String.split_at(start_cell.text, start_offset)
        start_cell = %{start_cell | text: start_text_left}
        new_cell_left = %{start_cell | id: Utils.new_id(), text: start_text_right}

        {end_text_left, end_text_right} = String.split_at(end_cell.text, end_offset)
        end_cell = %{end_cell | text: end_text_right}
        new_cell_right = %{end_cell | id: Utils.new_id(), text: end_text_left}

        new_cells =
          Enum.map([new_cell_left] ++ cells_between ++ [new_cell_right], fn cell ->
            new_modifiers = cell.modifiers |> Enum.concat([style]) |> Enum.dedup() |> Enum.sort()
            %{cell | modifiers: new_modifiers}
          end)

        new_selection = %Block.Selection{
          start_id: new_cell_left.id,
          end_id: new_cell_right.id,
          start_offset: 0,
          end_offset: String.length(new_cell_right.text)
        }

        %{
          block
          | cells: cells_before ++ new_cells ++ cells_after,
            selection: new_selection
        }
      else
        {cells_before, [start_cell | cells_after]} = Enum.split(cells, start_cell_index)

        {text_left, remaining_text} = String.split_at(start_cell.text, start_offset)
        {text_between, text_right} = String.split_at(remaining_text, end_offset - start_offset)

        new_modifiers =
          if style in start_cell.modifiers do
            List.delete(start_cell.modifiers, style)
          else
            start_cell.modifiers |> Enum.concat([style]) |> Enum.sort()
          end

        [_, selected_cell, _] =
          new_cells = [
            %{start_cell | text: text_left},
            %{start_cell | id: Utils.new_id(), text: text_between, modifiers: new_modifiers},
            %{start_cell | id: Utils.new_id(), text: text_right}
          ]

        new_selection = %{
          start_id: selected_cell.id,
          end_id: selected_cell.id,
          start_offset: 0,
          end_offset: String.length(selected_cell.text)
        }

        %{
          block
          | cells: cells_before ++ new_cells ++ cells_after,
            selection: new_selection
        }
      end

    index = Enum.find_index(editor.blocks, &(&1.id === block.id))
    new_blocks = List.replace_at(editor.blocks, index, new_block)

    %{editor | blocks: new_blocks}
  end

  @doc """
  Performs action of spliting a block like into two lines, where both stay part of the same block.

  This is the result of the user usually hitting Shift + Enter.
  """
  @spec split_line(Editor.t(), Block.t(), %{required(:selection) => map}) :: Editor.t()
  def split_line(%Editor{} = editor, %Block{type: type} = block, %{
        selection: %Block.Selection{} = selection
      })
      when type in ["p", "pre", "blockquote"] do
    [%Block{cells: cells_before}, %Block{cells: cells_after}] =
      block
      |> set_selection(selection)
      |> remove_selection()
      |> split_at_selection()

    br_cell = %Block.Cell{id: Utils.new_id(), modifiers: ["br"], text: ""}

    new_cells =
      cells_before
      |> Enum.concat([br_cell])
      |> Enum.concat(cells_after)

    [%Block.Cell{} = cell | _] = cells_after

    new_block = %{block | cells: new_cells, selection: Block.Selection.new_start_of(cell)}

    replace_block(editor, block, [new_block])
  end

  def split_line(%Editor{} = editor, %Block{}, %{}), do: editor

  @spec replace_block(Editor.t(), Block.t(), list(Block.t())) :: Editor.t()
  defp replace_block(%Editor{} = editor, %Block{} = block, new_blocks) when is_list(new_blocks) do
    case Enum.find_index(editor.blocks, &(&1.id === block.id)) do
      nil ->
        editor

      index when is_integer(index) ->
        new_blocks =
          editor.blocks
          |> List.replace_at(index, new_blocks)
          |> List.flatten()

        %{editor | blocks: new_blocks}
    end
  end

  @doc """
  Performs action of splitting a block into two separate blocks at current cursor position.

  This is the result of a user hitting Enter.

  The first block retains the type of the original.
  The second block is usually a P block.
  """
  @spec split_block(Editor.t(), Block.t(), %{required(:selection) => map}) :: Editor.t()
  def split_block(
        %Editor{} = editor,
        %Block{} = block,
        %{selection: %Block.Selection{} = selection}
      ) do
    [block_before, block_after] =
      block
      |> set_selection(selection)
      |> remove_selection()
      |> split_at_selection()

    new_type =
      case block.type do
        "ul" -> "ul"
        _ -> "p"
      end

    block_after = %{block_after | type: new_type}

    replace_block(editor, block, [block_before, block_after])
  end

  defp set_selection(%Block{} = block, %Block.Selection{} = selection) do
    Map.put(block, :selection, selection)
  end

  defp remove_selection(
         %Block{
           selection: %Block.Selection{
             start_id: id,
             end_id: end_id,
             start_offset: offset,
             end_offset: end_offset
           }
         } = block
       )
       when id == end_id and offset == end_offset do
    block
  end

  defp remove_selection(
         %Block{
           selection: %Block.Selection{
             start_id: id,
             end_id: end_id,
             start_offset: start_offset,
             end_offset: end_offset
           }
         } = block
       )
       when id == end_id and start_offset < end_offset do
    index = Enum.find_index(block.cells, &(&1.id === id))
    {cells_before, [cell | cells_after]} = Enum.split(block.cells, index)
    {cell_before, _cell_in, cell_after} = split_cell(cell, start_offset, end_offset)

    new_cells =
      cells_before
      |> Enum.concat([cell_before, cell_after])
      |> Enum.concat(cells_after)

    %{block | cells: new_cells, selection: Block.Selection.new_start_of(cell_after)}
  end

  defp remove_selection(
         %Block{
           selection: %Block.Selection{
             start_id: start_id,
             end_id: end_id,
             start_offset: start_offset,
             end_offset: end_offset
           }
         } = block
       )
       when start_id != end_id and start_offset != end_offset do
    index = Enum.find_index(block.cells, &(&1.id === start_id))
    {cells_before, [start_cell | rest]} = Enum.split(block.cells, index)
    {start_cell_before, _start_cell_after} = split_cell(start_cell, start_offset)

    index = Enum.find_index(rest, &(&1.id === end_id))
    {_end_cells_before, [end_cell | cells_after]} = Enum.split(rest, index)

    {_end_cell_before, end_cell_after} = split_cell(end_cell, end_offset)

    cells_before =
      cells_before
      |> Enum.concat([start_cell_before])
      |> Enum.reject(&empty_cell?/1)

    [%Block.Cell{} = cell_after | _] =
      cells_after =
      [end_cell_after]
      |> Enum.concat(cells_after)
      |> Enum.reject(&empty_cell?/1)

    new_cells = Enum.concat(cells_before, cells_after)

    %{block | cells: new_cells, selection: Block.Selection.new_start_of(cell_after)}
  end

  defp split_at_selection(
         %Block{
           selection: %Block.Selection{
             start_id: id,
             end_id: end_id,
             start_offset: offset,
             end_offset: end_offset
           }
         } = block
       )
       when id == end_id and offset == end_offset do
    index = Enum.find_index(block.cells, &(&1.id === id))
    {cells_before, [cell | cells_after]} = Enum.split(block.cells, index)

    {cell_before, cell_after} = split_cell(cell, offset)

    cells_before =
      cells_before
      |> Enum.concat([cell_before])
      |> Enum.reject(&empty_cell?/1)

    cells_after =
      [cell_after]
      |> Enum.concat(cells_after)
      |> Enum.reject(&empty_cell?/1)

    cells_after =
      if cells_after == [] do
        [Block.Cell.new()]
      else
        cells_after
      end

    selected_cell = Enum.at(cells_after, 0)

    [
      %{block | cells: cells_before, selection: Block.Selection.new_empty()},
      %{
        block
        | cells: cells_after,
          id: Utils.new_id(),
          selection: Block.Selection.new_start_of(selected_cell)
      }
    ]
  end

  @doc """
  Splits block into two at cursor, then pastes in the current
  cliboard contents of the editor, between the two.
  """
  @spec paste(Editor.t(), Block.t(), map) :: Editor.t()
  def paste(%Editor{clipboard: nil} = editor, %Block{} = _block, %{}), do: editor

  def paste(%Editor{} = editor, %Block{} = block, %{
        selection: %Block.Selection{} = selection
      }) do
    [%{cells: [first_cell | _]} = first_block | rest] =
      Enum.map(editor.clipboard, &Map.put(&1, :id, Utils.new_id()))

    first_block =
      Map.put(first_block, :selection, %Block.Selection{
        start_id: first_cell.id,
        end_id: first_cell.id,
        start_offset: 0,
        end_offset: 0
      })

    clipboard_blocks = [first_block | rest]

    [block_before, block_after] =
      block
      |> set_selection(selection)
      |> remove_selection()
      |> split_at_selection()

    new_blocks = Enum.reject([block_before] ++ clipboard_blocks ++ [block_after], &empty_block?/1)

    replace_block(editor, block, new_blocks)
  end

  @spec empty_block?(Block.t()) :: boolean
  defp empty_block?(%Block{cells: [%{text: ""}]}), do: true
  defp empty_block?(%Block{}), do: false

  defp empty_cell?(%Block.Cell{text: t, modifiers: m}) when t in ["", nil] and m != ["br"] do
    true
  end

  defp empty_cell?(%Block.Cell{}), do: false

  @spec split_cell(Block.Cell.t(), non_neg_integer()) :: {Block.Cell.t(), Block.Cell.t()}
  defp split_cell(%Block.Cell{id: _, modifiers: _, text: _} = cell, index) do
    {text_before, text_after} = String.split_at(cell.text, index)
    cell_before = %{cell | text: text_before}
    cell_after = %{cell | id: Utils.new_id(), text: text_after}
    {cell_before, cell_after}
  end

  @spec split_cell(Block.Cell.t(), non_neg_integer(), non_neg_integer()) ::
          {Block.Cell.t(), Block.Cell.t(), Block.Cell.t()}

  defp split_cell(%{id: _, text: _, modifiers: _} = cell, start_offset, end_offset)
       when start_offset < end_offset do
    {text_before, rest} = String.split_at(cell.text, start_offset)
    {text_in, text_after} = String.split_at(rest, end_offset - start_offset)

    {
      %{cell | text: text_before},
      %{cell | id: Utils.new_id(), text: text_in},
      %{cell | id: Utils.new_id(), text: text_after}
    }
  end

  @spec backspace_from_start(Editor.t(), Block.t()) :: Editor.t()
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

  @spec convert(Editor.t(), Block.t(), String.t()) :: Editor.t()
  defp convert(%Editor{} = editor, %Block{} = block, type)
       when type in ["p", "h1", "h2", "h3"] do
    index = Enum.find_index(editor.blocks, &(&1.id === block.id))

    if index >= 0 do
      new_block = %{block | type: type}
      new_blocks = List.replace_at(editor.blocks, index, new_block)
      %{editor | id: Utils.new_id(), blocks: new_blocks}
    else
      editor
    end
  end

  defp merge_previous(%Editor{} = editor, %_{} = block) do
    index = Enum.find_index(editor.blocks, &(&1 == block)) - 1

    if index >= 0 do
      %_{} = previous_block = Enum.at(editor.blocks, index)
      merged = %{merge_second_into_first(previous_block, block) | id: Utils.new_id()}
      last_cell = Enum.at(merged.cells, -1)
      selection = Block.Selection.new_end_of(last_cell)

      merged = set_selection(merged, selection)

      blocks = editor.blocks |> List.delete_at(index + 1) |> List.replace_at(index, merged)
      %{editor | blocks: blocks}
    else
      editor
    end
  end

  @spec merge_second_into_first(Block.t(), Block.t()) :: Block.t()
  defp merge_second_into_first(%Block{} = first_block, %Block{} = other_block) do
    new_cells =
      first_block.cells
      |> Enum.concat(other_block.cells)
      |> Enum.reject(&empty_cell?/1)

    %{first_block | cells: new_cells}
  end

  @spec resolve_transform(Block.t()) :: Block.t()
  defp resolve_transform(%Block{} = p) do
    case p.cells |> Enum.at(0) |> Map.get(:text) |> transform_type() do
      nil -> p
      other -> transform(p, other)
    end
  end

  @spec transform_type(String.t()) :: String.t() | nil
  defp transform_type("# " <> _), do: "h1"
  defp transform_type("## " <> _), do: "h2"
  defp transform_type("### " <> _), do: "h3"
  defp transform_type("* " <> _), do: "li"
  defp transform_type("```" <> _), do: "pre"
  defp transform_type("> " <> _), do: "blockquote"
  defp transform_type(_), do: nil

  @spec transform(Block.t(), String.t()) :: Block.t()
  defp transform(%Block{} = self, "h1") do
    %{
      self
      | id: Utils.new_id(),
        type: "h1",
        cells: replace_leading(self.cells, "# ", ""),
        selection: shift(self.selection, -2)
    }
  end

  defp transform(%Block{} = self, "h2") do
    %{
      self
      | id: Utils.new_id(),
        type: "h2",
        cells: replace_leading(self.cells, "## ", ""),
        selection: shift(self.selection, -3)
    }
  end

  defp transform(%Block{} = self, "h3") do
    %{
      self
      | id: Utils.new_id(),
        type: "h3",
        cells: replace_leading(self.cells, "### ", ""),
        selection: shift(self.selection, -4)
    }
  end

  defp transform(%Block{} = self, "pre") do
    %{
      self
      | id: Utils.new_id(),
        type: "pre",
        cells: replace_leading(self.cells, "```", ""),
        selection: shift(self.selection, -3)
    }
  end

  defp transform(%Block{} = self, "blockquote") do
    %{
      self
      | id: Utils.new_id(),
        type: "blockquote",
        cells: replace_leading(self.cells, "> ", ""),
        selection: shift(self.selection, -2)
    }
  end

  defp transform(%Block{} = self, "li") do
    %{
      self
      | id: Utils.new_id(),
        type: "li",
        cells: replace_leading(self.cells, "* ", ""),
        selection: shift(self.selection, -2)
    }
  end

  defp replace_leading([], _, _), do: []

  @spec replace_leading(list(Block.Cell.t()), String.t(), String.t()) :: list(Block.Cell.t())
  defp replace_leading([first | rest], from, to) do
    first = %{first | text: String.replace(first.text, from, to)}
    [first | rest]
  end

  @spec shift(Block.Selection.t(), integer) :: Block.Selection.t()
  defp shift(
         %{
           start_id: start_id,
           end_id: end_id,
           start_offset: start_offset,
           end_offset: end_offset
         },
         amount
       ) do
    end_offset = Kernel.max(end_offset + amount, 0)
    start_offset = Kernel.max(start_offset + amount, 0)

    %Block.Selection{
      start_id: start_id,
      end_id: end_id,
      start_offset: start_offset,
      end_offset: end_offset
    }
  end
end
