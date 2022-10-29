defmodule Philtre.Block.List do
  @moduledoc """
  Implements a list block

  Currently, the only supported form is the 1-level unordered list
  """

  use Phoenix.Component

  alias Philtre.Block
  alias Philtre.Block.ContentEditable
  alias Philtre.Block.ContentEditable.Cell
  alias Philtre.Block.ContentEditable.Selection
  alias Philtre.Block.List.Item
  alias Philtre.Editor
  alias Philtre.Editor.Engine
  alias Philtre.Editor.Utils

  require Logger

  defstruct [:id, :kind, :items]

  @type t :: %__MODULE__{}

  @behaviour Block

  @impl Block
  def id(%__MODULE__{id: id}), do: id

  @impl Block
  def type(%__MODULE__{}), do: "list"

  @impl Block
  def data(%__MODULE__{items: items}),
    do: %{
      "kind" => "unordered",
      "items" =>
        Enum.map(items, fn item ->
          %{
            "id" => item.contenteditable.id,
            "cells" => Enum.map(item.contenteditable.cells, &Cell.serialize/1)
          }
        end)
    }

  @impl Block
  def normalize(id, %{"kind" => kind, "items" => items}) do
    %__MODULE__{
      id: id,
      kind: kind,
      items:
        Enum.map(items, fn %{"id" => id, "cells" => cells} ->
          %__MODULE__.Item{
            contenteditable: %Block.ContentEditable{
              id: id,
              cells: Enum.map(cells, &Cell.normalize/1)
            }
          }
        end)
    }
  end

  @impl Block
  def render_live(%{block: _} = assigns) do
    ~H"""
    <ul data-block id={@block.id}>
      <%= for item <- @block.items do %>
        <li
          id={item.contenteditable.id}
          phx-hook="ContentEditable"
          contenteditable
          data-selection-end-id={item.contenteditable.selection.end_id}
          data-selection-end-offset={item.contenteditable.selection.end_offset}
          data-selection-start-id={item.contenteditable.selection.start_id}
          data-selection-start-offset={item.contenteditable.selection.start_offset}
          phx-target={@myself}>
          <%= for cell <- item.contenteditable.cells do %>
            <.cell cell={cell} />
          <% end %>
        </li>
      <% end %>
    </ul>
    """
  end

  defp cell(%{cell: %{id: id, modifiers: modifiers, text: text}} = assigns) do
    classes = ["philtre-cell"] |> Enum.concat(modifiers) |> Enum.join(" ") |> String.trim()

    ~H"""
    <span data-cell-id={id} class={classes}><%= text %></span>
    """
  end

  @impl Block
  def render_static(%{block: _} = assigns) do
    ~H"""
    <ul>
      <%= for item <- @block.items do %>
        <li>
          <%= for cell <- item.cells do %>
            <.static_cell :text={cell.text} :modifiers={cell.modifiers} />
          <% end %>
        </li>
      <% end %>
    </ul>
    """
  end

  defp static_cell(%{modifiers: ["bold" | rest]} = assigns) do
    ~H"""
    <strong><.static_cell text={@text} modifiers={rest} /></strong>
    """
  end

  defp static_cell(%{modifiers: ["italic" | rest]} = assigns) do
    ~H"""
    <em><.static_cell text={@text} modifiers={rest} /></em>
    """
  end

  defp static_cell(%{modifiers: []} = assigns) do
    ~H"""
    <%= @text %>
    """
  end

  def handle_event("update", %{"selection" => selection, "cells" => cells} = attrs, socket) do
    Logger.debug("update: #{inspect(attrs)}")

    %__MODULE__{} = block = socket.assigns.block

    %Selection{} = selection = Selection.normalize!(selection)

    # there is an edge case in ContentEditable.js that causes the one cell
    # inside a list item to be deleted when you backspace from `' '` to `''`
    # the `|| 0` ensures we default to the 0ths cell of the block, so it
    # rerenders.
    case get_focused_list_item_index(block, selection) do
      nil ->
        Logger.debug("Couldn't resolve selected item")

      item_index ->
        item = Enum.at(block.items, item_index)

        new_contenteditable =
          Engine.update(item.contenteditable, %{selection: selection, cells: cells})

        new_item = %{item | contenteditable: new_contenteditable}
        new_block = replace_item(block, item_index, [new_item])

        new_editor = Editor.replace_block(socket.assigns.editor, socket.assigns.block, [new_block])

        if new_editor !== socket.assigns.editor do
          send(self(), {:update, new_editor})
        end
    end

    {:noreply, socket}
  end

  def handle_event("split_block", %{"selection" => selection} = params, socket) do
    Logger.debug("split_block: #{inspect(params)}")

    %__MODULE__{} = block = socket.assigns.block

    %Selection{} = selection = Selection.normalize!(selection)

    case get_focused_list_item_index(block, selection) do
      nil ->
        Logger.debug("Item not found")

      item_index ->
        item = Enum.at(block.items, item_index)

        {block_a, block_b} = Engine.split_block(item.contenteditable, %{selection: selection})

        item_before = %{item | contenteditable: block_a}
        item_after = %{item | contenteditable: block_b}

        new_block = replace_item(block, item_index, [item_before, item_after])

        new_editor =
          Philtre.Editor.replace_block(socket.assigns.editor, socket.assigns.block, [new_block])

        if new_editor !== socket.assigns.editor do
          send(self(), {:update, new_editor})
        end
    end

    {:noreply, socket}
  end

  def handle_event("backspace_from_start", %{"selection" => selection} = params, socket) do
    Logger.debug("backspace_from_start: #{inspect(params)}")

    %__MODULE__{} = block = socket.assigns.block

    %Selection{} = selection = Selection.normalize!(selection)

    # current item is converted to a basic contenteditable
    item_index = get_focused_list_item_index(block, selection)
    %__MODULE__.Item{contenteditable: block_here} = Enum.at(block.items, item_index)
    block_here = %{block_here | id: Utils.new_id()}

    # previous items are split off into their own list block
    {items_before, _} = Enum.split(block.items, item_index)
    block_before = %{block | id: Utils.new_id(), items: items_before}

    # next items are split off into their own list block
    {_, items_after} = Enum.split(block.items, item_index + 1)
    block_after = %{block | id: Utils.new_id(), items: items_after}

    blocks =
      Enum.reject([block_before, block_here, block_after], fn
        %__MODULE__{items: []} -> true
        _ -> false
      end)

    new_editor = Editor.replace_block(socket.assigns.editor, socket.assigns.block, blocks)

    if new_editor !== socket.assigns.editor do
      send(self(), {:update, new_editor})
    end

    {:noreply, socket}
  end

  @impl Block
  def transform(%ContentEditable{} = block) do
    %__MODULE__{
      id: Utils.new_id(),
      kind: "unordered",
      items: [%Item{contenteditable: %{block | id: Utils.new_id()}}]
    }
  end

  defp get_focused_list_item_index(%__MODULE__{} = block, %Selection{} = selection) do
    # The js hook will sometimes completely remove a cell from the li,
    # in which case, the selection that gets sent will be for the li itself,
    # This is why we try to match on cell id first, followed by li
    Enum.find_index(block.items, fn %Block.List.Item{} = item ->
      Enum.any?(
        item.contenteditable.cells,
        &(&1.id === selection.start_id || &1.id === selection.end_id)
      )
    end) ||
      Enum.find_index(block.items, fn %Block.List.Item{} = item ->
        item.contenteditable.id === selection.start_id ||
          item.contenteditable.id === selection.end_id
      end)
  end

  @spec replace_item(t, integer, list(__MODULE__.Item.t())) :: t()
  defp replace_item(%__MODULE__{} = block, item_index, items) do
    new_items = block.items |> List.replace_at(item_index, items) |> List.flatten()
    %{block | items: new_items}
  end

  @spec merge(t, ContentEditable.t()) :: t
  def merge(%__MODULE__{} = self, %ContentEditable{} = editable) do
    [last_item | rest] = Enum.reverse(self.items)
    remaining_items = Enum.reverse(rest)

    new_last_item = %{
      last_item
      | contenteditable: %{
          last_item.contenteditable
          | cells: Enum.concat(last_item.contenteditable.cells, editable.cells)
        }
    }

    %{self | items: Enum.concat(remaining_items, [new_last_item])}
  end

  @impl Block
  @spec cells(t) :: list(ContentEditable.Cell.t())
  def cells(%__MODULE__{} = list) do
    list.items
    |> Enum.map(& &1.contenteditable.cells)
    |> List.flatten()
  end

  @impl Block
  @spec set_selection(t, Selection.t()) :: t
  def set_selection(%__MODULE__{} = list, %Selection{} = selection) do
    index = get_focused_list_item_index(list, selection)
    item = Enum.at(list.items, index)

    item = %{
      item
      | contenteditable: ContentEditable.set_selection(item.contenteditable, selection)
    }

    %{list | items: List.replace_at(list.items, index, item)}
  end

  @impl Block
  @spec reduce(t) :: t
  def reduce(%__MODULE__{} = list) do
    new_items =
      Enum.map(list.items, fn %__MODULE__.Item{} = item ->
        %{item | contenteditable: ContentEditable.reduce(item.contenteditable)}
      end)

    %{list | items: new_items}
  end
end
