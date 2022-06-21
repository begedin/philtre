defmodule Philtre.Editor.Engine do
  @moduledoc """
  Holds shared logic for modifying editor blocks
  """

  alias Philtre.Block.Code
  alias Philtre.Block.ContentEditable
  alias Philtre.Block.ContentEditable.Cell
  alias Philtre.Block.ContentEditable.CleanEmptyCells
  alias Philtre.Block.ContentEditable.Reduce
  alias Philtre.Block.ContentEditable.Selection
  alias Philtre.Block.Table
  alias Philtre.Editor
  alias Philtre.Editor.Utils

  @spec update(
          Editor.t(),
          ContentEditable.t(),
          %{required(:selection) => map, required(:cells) => list(map)}
        ) :: Editor.t()
  def update(%Editor{} = editor, %ContentEditable{} = block, %{selection: nil, cells: []}) do
    %Cell{} = cell = Cell.new()

    %ContentEditable{} =
      new_block =
      block
      |> Map.put(:cells, [cell])
      |> Map.put(:selection, Selection.new_start_of(cell))
      |> resolve_transform()

    Editor.replace_block(editor, block, [new_block])
  end

  def update(%Editor{} = editor, %ContentEditable{cells: old_cells} = block, %{
        selection: selection,
        cells: new_cells
      }) do
    # the new cells are content received from the client side of the ContentEditable hook
    # and should be the exact correct content of the updated block
    new_cells =
      Enum.map(new_cells, fn %{"id" => id, "modifiers" => modifiers, "text" => text} ->
        %Cell{id: id, modifiers: modifiers, text: text}
      end)

    # the remainder here probably isn't necessary and updated cells should just equal to new cells
    # but just in case, until more testing is added, we do not fully trust the frontend and instead
    # manually match old with new cell records to update them
    new_ids = Enum.map(new_cells, & &1.id)
    remaining_cells = Enum.filter(old_cells, &(&1.id in new_ids))

    updated_cells =
      Enum.map(remaining_cells, fn %Cell{} = cell ->
        %Cell{} = params = Enum.find(new_cells, &(&1.id === cell.id))
        %{cell | modifiers: params.modifiers, text: params.text}
      end)

    new_block = resolve_transform(%{block | cells: updated_cells, selection: selection})

    Editor.replace_block(editor, block, [new_block])
  end

  @spec toggle_style_on_selection(
          Editor.t(),
          ContentEditable.t(),
          %{
            required(:selection) => map,
            required(:style) => String.t()
          }
        ) :: Editor.t()
  def toggle_style_on_selection(%Editor{} = editor, %ContentEditable{} = block, %{
        selection: %Selection{
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

        new_selection = %Selection{
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

        new_selection = %Selection{
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

    new_block =
      new_block
      |> CleanEmptyCells.call()
      |> Reduce.call()

    index = Enum.find_index(editor.blocks, &(&1.id === block.id))
    new_blocks = List.replace_at(editor.blocks, index, new_block)

    %{editor | blocks: new_blocks}
  end

  def add_block(%Editor{} = editor, %_{id: _} = block) do
    index = Enum.find_index(editor.blocks, &(&1.id === block.id))

    cell = %Cell{}

    new_block = %ContentEditable{
      cells: [cell],
      id: Utils.new_id(),
      type: "p",
      selection: Selection.new_start_of(cell)
    }

    new_blocks = List.insert_at(editor.blocks, index + 1, new_block)
    %{editor | blocks: new_blocks}
  end

  @doc """
  Performs action of spliting a block like into two lines, where both stay part of the same block.

  This is the result of the user usually hitting Shift + Enter.
  """
  @spec split_line(Editor.t(), ContentEditable.t(), %{required(:selection) => map}) :: Editor.t()
  def split_line(%Editor{} = editor, %ContentEditable{type: type} = block, %{
        selection: %Selection{} = selection
      })
      when type in ["p", "pre", "blockquote"] do
    new_block =
      block
      |> set_selection(selection)
      |> split_line_at_selection()

    Editor.replace_block(editor, block, [new_block])
  end

  def split_line(%Editor{} = editor, %ContentEditable{}, %{}), do: editor

  @spec split_line_at_selection(ContentEditable.t()) :: ContentEditable.t()
  defp split_line_at_selection(
         %ContentEditable{
           selection: %Selection{
             start_id: start_id,
             end_id: end_id,
             start_offset: start_offset,
             end_offset: end_offset
           }
         } = block
       )
       when start_id == end_id and start_offset == end_offset do
    cell_index = Enum.find_index(block.cells, &(&1.id === start_id))
    %Cell{} = cell = Enum.at(block.cells, cell_index)

    {text_before, text_after} = String.split_at(cell.text, start_offset)

    new_text =
      [text_before, "\n", text_after]
      |> Enum.join()
      |> fix_double_newlines()
      |> fix_trailing_newline()

    %Cell{} = new_cell = %{cell | text: new_text}
    new_cells = List.replace_at(block.cells, cell_index, new_cell)

    new_selection = shift(block.selection, 1)
    %{block | cells: new_cells, selection: new_selection}
  end

  defp split_line_at_selection(%ContentEditable{} = block), do: block

  @spec fix_double_newlines(String.t()) :: String.t()
  defp fix_double_newlines(text), do: String.replace(text, "\n\n", "\n", global: true)

  # The browser will ignore the final newline in html, so to enable us to add a
  # new line at the end of a block without having to hit Shift+Enter twice, we
  # have to duplicate the trailing newline
  @spec fix_trailing_newline(String.t()) :: String.t()
  defp fix_trailing_newline(text) do
    if String.ends_with?(text, "\n") do
      text <> "\n"
    else
      text
    end
  end

  @doc """
  Performs action of splitting a block into two separate blocks at current cursor position.

  This is the result of a user hitting Enter.

  The first block retains the type of the original.
  The second block is usually a P block.
  """
  @spec split_block(Editor.t(), ContentEditable.t(), %{required(:selection) => map}) :: Editor.t()
  def split_block(
        %Editor{} = editor,
        %ContentEditable{} = block,
        %{selection: %Selection{} = selection}
      ) do
    [block_before, block_after] =
      block
      |> set_selection(selection)
      |> remove_selection()
      |> split_at_selection()

    new_type =
      case block.type do
        "li" -> "li"
        _ -> "p"
      end

    block_before =
      if empty_block?(block_before) do
        %{block_before | cells: [Cell.new()]}
      else
        block_before
      end

    block_after =
      if empty_block?(block_after) do
        cell = Cell.new()
        selection = Selection.new_start_of(cell)
        %{block_after | cells: [cell], selection: selection}
      else
        block_after
      end

    block_after = %{block_after | type: new_type}

    Editor.replace_block(editor, block, [block_before, block_after])
  end

  defp set_selection(%ContentEditable{} = block, %Selection{} = selection) do
    Map.put(block, :selection, selection)
  end

  defp remove_selection(
         %ContentEditable{
           selection: %Selection{
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
         %ContentEditable{
           selection: %Selection{
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

    %{block | cells: new_cells, selection: Selection.new_start_of(cell_after)}
  end

  defp remove_selection(
         %ContentEditable{
           selection: %Selection{
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

    [%Cell{} = cell_after | _] =
      cells_after =
      [end_cell_after]
      |> Enum.concat(cells_after)
      |> Enum.reject(&empty_cell?/1)

    new_cells = Enum.concat(cells_before, cells_after)

    %{block | cells: new_cells, selection: Selection.new_start_of(cell_after)}
  end

  defp split_at_selection(
         %ContentEditable{
           selection: %Selection{
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
        [Cell.new()]
      else
        cells_after
      end

    selected_cell = Enum.at(cells_after, 0)

    [
      %{block | cells: cells_before, selection: Selection.new_empty()},
      %{
        block
        | cells: cells_after,
          id: Utils.new_id(),
          selection: Selection.new_start_of(selected_cell)
      }
    ]
  end

  @doc """
  Splits block into two at cursor, then pastes in the current
  cliboard contents of the editor, between the two.
  """
  @spec paste(Editor.t(), ContentEditable.t(), map) :: Editor.t()
  def paste(%Editor{clipboard: nil} = editor, %ContentEditable{} = _block, %{}), do: editor

  def paste(%Editor{} = editor, %ContentEditable{} = block, %{
        selection: %Selection{} = selection
      }) do
    [%{cells: [first_cell | _]} = first_block | rest] =
      Enum.map(editor.clipboard, &Map.put(&1, :id, Utils.new_id()))

    first_block =
      Map.put(first_block, :selection, %Selection{
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

    Editor.replace_block(editor, block, new_blocks)
  end

  @spec empty_block?(ContentEditable.t()) :: boolean
  defp empty_block?(%ContentEditable{cells: []}), do: true
  defp empty_block?(%ContentEditable{cells: [cell]}), do: empty_cell?(cell)
  defp empty_block?(%ContentEditable{}), do: false

  defp empty_cell?(%Cell{text: t}) when t in ["", nil, " ", "&nbsp;", " "], do: true
  defp empty_cell?(%Cell{}), do: false

  @spec split_cell(Cell.t(), non_neg_integer()) :: {Cell.t(), Cell.t()}
  defp split_cell(%Cell{id: _, modifiers: _, text: _} = cell, index) do
    {text_before, text_after} = String.split_at(cell.text, index)
    cell_before = %{cell | text: text_before}
    cell_after = %{cell | id: Utils.new_id(), text: text_after}
    {cell_before, cell_after}
  end

  @spec split_cell(Cell.t(), non_neg_integer(), non_neg_integer()) ::
          {Cell.t(), Cell.t(), Cell.t()}

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

  @spec backspace_from_start(Editor.t(), ContentEditable.t()) :: Editor.t()
  def backspace_from_start(%Editor{} = editor, %ContentEditable{type: "p"} = block) do
    merge_previous(editor, block)
  end

  def backspace_from_start(%Editor{} = editor, %ContentEditable{type: "h1"} = block) do
    convert(editor, block, "h2")
  end

  def backspace_from_start(%Editor{} = editor, %ContentEditable{type: "h2"} = block) do
    convert(editor, block, "h3")
  end

  def backspace_from_start(%Editor{} = editor, %ContentEditable{} = block) do
    convert(editor, block, "p")
  end

  @spec convert(Editor.t(), ContentEditable.t(), String.t()) :: Editor.t()
  defp convert(%Editor{} = editor, %ContentEditable{} = block, type)
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
      last_cell = Enum.at(previous_block.cells, -1)

      selection =
        cond do
          not is_nil(last_cell) and not empty_cell?(last_cell) ->
            Selection.new_end_of(last_cell)

          not is_nil(first_cell) and not empty_cell?(first_cell) ->
            Selection.new_start_of(first_cell)

          Enum.count(merged.cells) == 1 ->
            [only_cell] = merged.cells
            Selection.new_start_of(only_cell)
        end

      merged = merged |> set_selection(selection) |> Reduce.call()

      blocks = editor.blocks |> List.delete_at(index + 1) |> List.replace_at(index, merged)
      %{editor | blocks: blocks}
    else
      editor
    end
  end

  @spec merge_second_into_first(ContentEditable.t(), ContentEditable.t()) :: ContentEditable.t()
  defp merge_second_into_first(%ContentEditable{} = first_block, %ContentEditable{} = other_block) do
    new_cells =
      first_block.cells
      |> Enum.concat(other_block.cells)
      |> Enum.reject(&empty_cell?/1)

    ensure_single_cell(%{first_block | cells: new_cells})
  end

  @spec ensure_single_cell(ContentEditable.t()) :: ContentEditable.t()
  defp ensure_single_cell(%ContentEditable{cells: []} = block), do: %{block | cells: [Cell.new()]}
  defp ensure_single_cell(%ContentEditable{} = block), do: block

  @transforms [
    %{
      prefixes: ["* ", "* "],
      kind: "li"
    },
    %{
      prefixes: ["# ", "# "],
      kind: "h1"
    },
    %{
      prefixes: ["## ", "## "],
      kind: "h2"
    },
    %{
      prefixes: ["### ", "### "],
      kind: "h3"
    },
    %{
      prefixes: ["```"],
      kind: "pre"
    },
    %{
      prefixes: ["> ", "> "],
      kind: "blockquote"
    },
    %{
      prefixes: ["/table"],
      kind: "table"
    },
    %{
      prefixes: ["/code"],
      kind: "code"
    }
  ]

  @type transform :: %{required(:prefixes) => list(String.t()), kind: String.t()}

  # checks for transform wildcard character sequences in the contents of the block (first cell)
  # and applies any matched transform
  @spec resolve_transform(ContentEditable.t()) :: ContentEditable.t()
  defp resolve_transform(%ContentEditable{} = block) do
    with %Cell{text: text} <- Enum.at(block.cells, 0),
         %{} = transform <- match_transform(text) do
      transform(block, transform)
    else
      nil -> block
    end
  end

  defp match_transform(text) when is_binary(text) do
    Enum.find(@transforms, fn %{prefixes: prefixes, kind: _kind} ->
      # we put a space character inside of every new cell, which we clear out at the end.
      # if the prefix matches exactly the content of the cell, that means it's the initial
      # space character and not an actual transform we're doing
      Enum.any?(prefixes, &(String.starts_with?(text, &1) && text !== &1))
    end)
  end

  # applies a transform to a block, which usually changes its time and, if it's a
  # regular content-editable block transform, updates selection offsets, as the
  # wildcard character sequence triggering the transform will be removed
  @spec transform(ContentEditable.t(), transform) :: ContentEditable.t()
  defp transform(%ContentEditable{} = self, %{kind: "table", prefixes: prefixes}) do
    {new_cells, _shift} = drop_leading(self.cells, prefixes)

    %Table{id: Utils.new_id(), rows: [Enum.map(new_cells, &String.trim(&1.text))]}
  end

  defp transform(%ContentEditable{}, %{kind: "code"}) do
    %Code{id: Utils.new_id(), content: "", language: "elixir", focused: true}
  end

  defp transform(%ContentEditable{} = self, %{kind: kind, prefixes: prefixes}) do
    {new_cells, shift} = drop_leading(self.cells, prefixes)
    type = kind

    %{
      self
      | id: Utils.new_id(),
        type: type,
        cells: new_cells,
        selection: shift(self.selection, -shift)
    }
  end

  @spec drop_leading(list(Cell.t()), list(String.t())) :: {list(Cell.t()), integer}
  defp drop_leading([], _), do: []

  defp drop_leading([%{text: text} = first | rest], prefixes) when is_list(prefixes) do
    prefix = Enum.find(prefixes, &String.starts_with?(text, &1))
    replaced = String.replace(first.text, prefix, "")

    # we need to make sure the transformed cell has at least a single "fake space"
    # character into which the editor can focus

    # this can probably be written more cleanly

    offset =
      case replaced do
        "" -> String.length(prefix) - 1
        _other -> String.length(prefix)
      end

    new_text =
      case replaced do
        "" -> " "
        other -> other
      end

    first = %{first | text: new_text}
    {[first | rest], offset}
  end

  @spec shift(Selection.t(), integer) :: Selection.t()
  defp shift(
         %Selection{
           start_id: start_id,
           end_id: end_id,
           start_offset: start_offset,
           end_offset: end_offset
         },
         amount
       ) do
    end_offset = Kernel.max(end_offset + amount, 0)
    start_offset = Kernel.max(start_offset + amount, 0)

    %Selection{
      start_id: start_id,
      end_id: end_id,
      start_offset: start_offset,
      end_offset: end_offset
    }
  end
end
