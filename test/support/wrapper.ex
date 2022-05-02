defmodule Philtre.Wrapper do
  @moduledoc """
  Defines a view and a set of utility functions to test how the editor
  component interacts with the view.

  Editor tests should only ever interact with the component via functions defined here.
  """
  use Phoenix.LiveView

  import Phoenix.LiveView.Helpers
  import Phoenix.LiveViewTest

  alias Philtre.Editor
  alias Philtre.Editor.Block
  alias Phoenix.LiveViewTest.View

  @doc false
  @impl Phoenix.LiveView
  def mount(:not_mounted_at_router, _session, socket) do
    {:ok, assign(socket, :editor, Editor.new())}
  end

  @doc false
  @impl Phoenix.LiveView
  def handle_info({:update, %Editor{} = editor}, socket) do
    {:noreply, assign(socket, :editor, editor)}
  end

  @doc false
  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.live_component module={Editor} id={@editor.id} editor={@editor} />
    """
  end

  @doc """
  Sets the editor struct of the component to the specified value.

  Convenient when we want to quickly get to a complex state of the editor
  struct, without performining individual updates.
  """
  def set_editor(%View{} = view, %Editor{} = editor) do
    send(view.pid, {:update, editor})
  end

  @doc """
  Retrieves the current editor from the component state
  """
  def get_editor(%View{} = view) do
    %{socket: %{assigns: %{editor: %Editor{} = editor}}} = :sys.get_state(view.pid)

    editor
  end

  def flush(%View{} = view) do
    :sys.get_state(view.pid)
  end

  @doc """
  Retrieves block at specified index
  """
  def block_at(%View{} = view, index) do
    %Editor{blocks: blocks} = get_editor(view)
    Enum.at(blocks, index)
  end

  @doc """
  Sends newline command at the location
  """
  def trigger_split_block(%View{} = view, :end_of_page) do
    %Editor{} = editor = get_editor(view)
    trigger_split_block(view, List.last(editor.blocks), :end)
  end

  @model %{selection: "[id^=editor__selection__]", history: "[id^=editor__history__]"}

  @doc """
  Sends newline command at the location
  """
  def trigger_split_block(%View{} = view, %_{cells: _} = block, :end) do
    end_cell = Enum.at(block.cells, -1)

    trigger_split_block(view, block, %{
      selection: %{
        start_id: end_cell.id,
        end_id: end_cell.id,
        start_offset: String.length(end_cell.text),
        end_offset: String.length(end_cell.text)
      }
    })
  end

  def trigger_split_block(%View{} = view, index, %{selection: selection})
      when is_integer(index) do
    trigger_split_block(view, block_at(view, index), %{selection: selection})
  end

  def trigger_split_block(%View{} = view, %_{} = block, %{selection: selection}) do
    view
    |> element("##{block.id}")
    |> render_hook("split_block", %{"selection" => selection})
  end

  @doc """
  Updates cell at specified location with specified value
  """
  def trigger_update(%View{} = view, index, %{selection: selection, cells: cells})
      when is_integer(index) do
    trigger_update(view, block_at(view, index), %{selection: selection, cells: cells})
  end

  def trigger_update(%View{} = view, %_{} = block, %{selection: selection, cells: cells}) do
    view
    |> element("##{block.id}")
    |> render_hook("update", %{"selection" => selection, "cells" => cells})
  end

  @doc """
  Simulates downgrade of a block (presing backspace from index 0 of first cell)
  """
  def trigger_backspace_from_start(%View{} = view, index) when is_integer(index) do
    trigger_backspace_from_start(view, block_at(view, index))
  end

  def trigger_backspace_from_start(
        %View{} = view,
        %Block{cells: [%Block.Cell{} = cell | _]} = block
      ) do
    view
    |> element("##{block.id}")
    |> render_hook("backspace_from_start", %{
      start_id: cell.id,
      end_id: cell.id,
      start_offset: 0,
      end_offset: 0
    })
  end

  def trigger_undo(%View{} = view) do
    view
    |> element(@model.history)
    |> render_hook("undo")
  end

  def trigger_redo(%View{} = view) do
    view
    |> element(@model.history)
    |> render_hook("redo")
  end

  @doc """
  Simulates selection of a block
  """
  def select_blocks(%View{} = view, block_ids) when is_list(block_ids) do
    view
    |> element(@model.selection)
    |> render_hook("select_blocks", %{"block_ids" => block_ids})
  end

  @doc """
  Simulates copy action of selected blocks
  """
  def copy_blocks(%View{} = view, block_ids) when is_list(block_ids) do
    view
    |> element(@model.selection)
    |> render_hook("copy_blocks", %{"block_ids" => block_ids})
  end

  @doc """
  Simulates paste action of selected blocks
  """
  def paste_blocks(%View{} = view, index, %{selection: selection}) when is_integer(index) do
    paste_blocks(view, block_at(view, index), %{selection: selection})
  end

  def paste_blocks(%View{} = view, %Block{} = block, %{selection: selection}) do
    view
    |> element("##{block.id}")
    |> render_hook("paste_blocks", %{"selection" => selection})
  end

  def block_text(%View{} = view, index) when is_integer(index) do
    %_{} = block = block_at(view, index)
    Editor.text(block)
  end
end
