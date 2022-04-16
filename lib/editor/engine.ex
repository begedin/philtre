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
  def update(%Editor{} = editor, %Block{} = block, %{
        selection: %{
          "start_id" => start_id,
          "end_id" => end_id,
          "start_offset" => start_offset,
          "end_offset" => end_offset
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

    replace_block(editor, block, new_block)
  end

  @spec toggle_style_on_selection(
          Editor.t(),
          Block.t(),
          %{required(:selection) => map, required(:style) => String.t()}
        ) :: Editor.t()
  def toggle_style_on_selection(%Editor{} = editor, %Block{} = block, %{
        selection: %{
          "start_id" => start_id,
          "end_id" => end_id,
          "start_offset" => start_offset,
          "end_offset" => end_offset
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
        selection: %{
          "start_id" => start_id,
          "end_id" => end_id,
          "start_offset" => start_offset,
          "end_offset" => end_offset
        }
      })
      when type in ["p", "pre", "blockquote"] do
    if start_id !== end_id, do: raise("selection is not 0")
    if start_offset !== end_offset, do: raise("selection is not 0")
    cells = block.cells
    cell_index = Enum.find_index(cells, &(&1.id === start_id))
    cell = Enum.at(cells, cell_index)

    {cell_before, cell_after} = split_cell(cell, start_offset)

    {cells_before, [^cell | cells_after]} = Enum.split(cells, cell_index)

    br_cell = %{id: Utils.new_id(), modifiers: ["br"], text: ""}

    new_cells = cells_before ++ [cell_before, br_cell, cell_after] ++ cells_after

    replace_block(editor, block, %{block | cells: new_cells})
  end

  def split_line(%Editor{} = editor, %Block{}, %{}), do: editor

  @spec replace_block(Editor.t(), Block.t(), Block.t() | list(Block.t())) :: Editor.t()
  defp replace_block(%Editor{} = editor, %Block{} = block, %Block{} = new_block) do
    replace_block(editor, block, [new_block])
  end

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

  @spec split_cell(Block.Cell.t(), non_neg_integer()) :: {Block.Cell.t(), Block.Cell.t()}
  defp split_cell(%Block.Cell{id: _, modifiers: _, text: _} = cell, index) do
    {text_before, text_after} = String.split_at(cell.text, index)
    cell_before = %{cell | text: text_before}
    cell_after = %{cell | id: Utils.new_id(), text: text_after}
    {cell_before, cell_after}
  end

  @doc """
  Performs action of splitting a block into two separate blocks at current cursor position.

  This is the result of a user hitting Enter.

  The first block retains the type of the original.
  The second block is usually a P block.
  """
  @spec split_block(Editor.t(), Block.t(), %{required(:selection) => map}) :: Editor.t()
  def split_block(%Editor{} = editor, %Block{} = block, %{
        selection: %{
          "start_id" => start_id,
          "end_id" => end_id,
          "start_offset" => start_offset,
          "end_offset" => end_offset
        }
      }) do
    if start_id !== end_id, do: raise("selection is not 0")
    if start_offset !== end_offset, do: raise("selection is not 0")

    cells = block.cells
    cell_index = Enum.find_index(cells, &(&1.id === start_id))
    cell = Enum.at(cells, cell_index)

    {cell_before, cell_after} = split_cell(cell, start_offset)

    {block_before, block_after} = do_split_block(block, cell_index)

    block_before = %{
      block_before
      | cells: block_before.cells ++ [cell_before],
        selection: %Block.Selection{}
    }

    after_type =
      case block.type do
        "ul" -> "ul"
        _other -> "p"
      end

    block_after = %{
      block_after
      | cells: [cell_after] ++ block_after.cells,
        type: after_type,
        selection: %Block.Selection{
          start_id: cell_after.id,
          end_id: cell_after.id,
          start_offset: 0,
          end_offset: 0
        }
    }

    replace_block(editor, block, [block_before, block_after])
  end

  @spec do_split_block(Block.t(), non_neg_integer()) :: {Block.t(), Block.t()}
  defp do_split_block(%Block{} = block, cell_index) do
    cells = block.cells

    {cells_before, [_removed_cell | cells_after]} = Enum.split(cells, cell_index)

    block_before = %{block | cells: cells_before}
    block_after = %{block | id: Utils.new_id(), cells: cells_after}

    {block_before, block_after}
  end

  @doc """
  Splits block into two at cursor, then pastes in the current
  cliboard contents of the editor, between the two.
  """
  @spec paste(Editor.t(), Block.t(), map) :: Editor.t()
  def paste(%Editor{clipboard: nil} = editor, %Block{} = _block, %{}), do: editor

  def paste(%Editor{} = editor, %Block{} = block, %{
        selection: %{
          "start_id" => start_id,
          "end_id" => end_id,
          "start_offset" => start_offset,
          "end_offset" => end_offset
        }
      }) do
    [%{cells: [first_cell | _]} = first_block | rest] =
      Enum.map(editor.clipboard, &Map.put(&1, :id, Utils.new_id()))

    first_block =
      Map.put(first_block, :selection, %{
        start_id: first_cell.id,
        end_id: first_cell.id,
        start_offset: 0,
        end_offset: 0
      })

    clipboard_blocks = [first_block | rest]

    [block_before, block_after] =
      case split_at_selection_as_block(block, %{
             start_id: start_id,
             end_id: end_id,
             start_offset: start_offset,
             end_offset: end_offset
           }) do
        [block_before, _block_in, block_after] -> [block_before, block_after]
        [block_before, block_after] -> [block_before, block_after]
      end

    new_blocks = Enum.reject([block_before] ++ clipboard_blocks ++ [block_after], &empty_block?/1)

    replace_block(editor, block, new_blocks)
  end

  @spec empty_block?(Block.t()) :: boolean
  defp empty_block?(%Block{cells: [%{text: ""}]}), do: true
  defp empty_block?(%Block{}), do: false

  @spec split_at_selection_as_block(Block.t(), Block.Selection.t()) :: list(Block.t())
  defp split_at_selection_as_block(
         %Block{} = block,
         %{
           start_id: start_id,
           end_id: end_id,
           start_offset: start_offset,
           end_offset: end_offset
         }
       )
       when start_id == end_id do
    cells = block.cells

    cell_index = Enum.find_index(cells, &(&1.id === start_id))
    {cells_before, [cell | cells_after]} = Enum.split(cells, cell_index)

    case split_cell(cell, start_offset, end_offset) do
      [cell_before, cell_after] ->
        [
          %{block | cells: cells_before ++ [cell_before] ++ cells_after},
          %{block | id: Utils.new_id(), cells: [cell_after] ++ cells_after}
        ]

      [cell_before, cell_in, cell_after] ->
        [
          %{block | cells: cells_before ++ [cell_before] ++ cells_after},
          %{block | id: Utils.new_id(), cells: [cell_in]},
          %{block | id: Utils.new_id(), cells: [cell_after] ++ cells_after}
        ]
    end
  end

  defp split_at_selection_as_block(
         %Block{} = block,
         %{
           start_id: start_id,
           end_id: end_id,
           start_offset: start_offset,
           end_offset: end_offset
         }
       ) do
    cells = block.cells
    start_index = Enum.find_index(cells, &(&1.id === start_id))

    {cells_before, [start_cell | rest]} = Enum.split(cells, start_index)
    [start_cell_in, start_cell_out] = split_cell(start_cell, start_offset, start_offset)

    end_index = Enum.find_index(rest, &(&1.id === end_id))
    {cells_in, [end_cell | cells_after]} = Enum.split(rest, end_index)
    [end_cell_in, end_cell_out] = split_cell(end_cell, end_offset, end_offset)

    [
      %{block | cells: cells_before ++ [start_cell_in]},
      %{block | id: Utils.new_id(), cells: [start_cell_out] ++ cells_in ++ [end_cell_in]},
      %{block | id: Utils.new_id(), cells: [end_cell_out] ++ cells_after}
    ]
  end

  @spec split_cell(Block.Cell.t(), non_neg_integer(), non_neg_integer()) :: list(Block.Cell.t())
  defp split_cell(%{id: _, text: _, modifiers: _} = cell, start_offset, end_offset)
       when start_offset == end_offset do
    {text_before, text_after} = String.split_at(cell.text, start_offset)

    [
      %{cell | text: text_before},
      %{cell | id: Utils.new_id(), text: text_after}
    ]
  end

  defp split_cell(%{id: _, text: _, modifiers: _} = cell, start_offset, end_offset)
       when start_offset < end_offset do
    {text_before, rest} = String.split_at(cell.text, start_offset)
    {text_in, text_after} = String.split_at(rest, end_offset - start_offset)

    [
      %{cell | text: text_before},
      %{cell | id: Utils.new_id(), text: text_in},
      %{cell | id: Utils.new_id(), text: text_after}
    ]
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

      first_cell = Enum.at(block.cells, 0)

      merged = %{
        merged
        | selection: %Block.Selection{
            start_id: first_cell.id,
            end_id: first_cell.id,
            start_offset: 0,
            end_offset: 0
          }
      }

      blocks = editor.blocks |> List.delete_at(index + 1) |> List.replace_at(index, merged)
      %{editor | blocks: blocks}
    else
      editor
    end
  end

  @spec merge_second_into_first(Block.t(), Block.t()) :: Block.t()
  defp merge_second_into_first(%Block{} = first_block, %Block{} = other_block) do
    %{first_block | cells: first_block.cells ++ other_block.cells}
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
    %{start_id: start_id, end_id: end_id, start_offset: start_offset, end_offset: end_offset}
  end
end
