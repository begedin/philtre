defmodule EditorTest.Wrapper do
  @moduledoc """
  Defines a view and a set of utility functions to test how the editor
  component interacts with the view.

  Editor tests should only ever interact with the component via functions defined here.
  """
  use Phoenix.LiveView

  import Phoenix.LiveView.Helpers
  import Phoenix.LiveViewTest

  alias Editor.Block
  alias Editor.Cell
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
    <.live_component module={Editor} id="editor" editor={@editor} />
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

  @doc """
  Retrieves block at specified index
  """
  def block_at(%View{} = view, index) do
    %Editor{page: %{blocks: blocks}} = get_editor(view)
    Enum.at(blocks, index)
  end

  @doc """
  Retrieves block by specified id
  """
  def get_block_by_id(%View{} = view, block_id) do
    %Editor{page: %{blocks: blocks}} = get_editor(view)
    Enum.find(blocks, &(&1.id === block_id))
  end

  @doc """
  Retrieves cell by specified id
  """
  def get_cell_by_id(%View{} = view, cell_id) do
    %Editor{page: %{blocks: blocks}} = get_editor(view)

    blocks
    |> Enum.map(& &1.cells)
    |> List.flatten()
    |> Enum.find(&(&1.id === cell_id))
  end

  @doc """
  Sends newline command at the location
  """
  def newline(%View{} = view, :end_of_page) do
    %Editor{} = editor = get_editor(view)
    newline(view, List.last(editor.page.blocks), :end_of_last_cell)
  end

  @doc """
  Retrieve cursor index
  """
  def cursor_index(%View{} = view) do
    %Editor{} = editor = get_editor(view)
    editor.page.cursor_index
  end

  @doc """
  Retrieve active cell id of the page
  """
  def active_cell_id(%View{} = view) do
    %Editor{} = editor = get_editor(view)
    editor.page.active_cell_id
  end

  @model %{selection: "[id^=editor__selection__]"}

  defp get_cell_element(%View{} = view, cell_id) do
    element(view, "[id=cell-#{cell_id}]")
  end

  defp get_block_by_cell_id(%View{} = view, cell_id) do
    %Editor{} = editor = get_editor(view)

    Enum.find(editor.page.blocks, fn %Block{} = block ->
      Enum.any?(block.cells, &(&1.id === cell_id))
    end)
  end

  @doc """
  Sends newline command at the location
  """
  def newline(%View{} = view, %Block{} = block, :end_of_last_cell) do
    newline(view, List.last(block.cells), :end)
  end

  def newline(%View{} = view, %Cell{} = cell, :end) do
    newline(view, cell, String.length(cell.content))
  end

  def newline(%View{} = view, %Cell{id: cell_id}, index) when is_integer(index) do
    view
    |> get_cell_element(cell_id)
    |> render_hook("newline", %{
      "cell_id" => cell_id,
      "index" => index
    })
  end

  @doc """
  Updates cell at specified location with specified value
  """
  def push_content(%View{} = view, :end_of_page, content) when is_binary(content) do
    %Editor{} = editor = get_editor(view)
    %Block{} = last_block = List.last(editor.page.blocks)
    %Cell{} = last_cell = List.last(last_block.cells)

    push_content(view, last_cell, content)
  end

  def push_content(%View{} = view, %Cell{} = cell, value) do
    %Block{} = block = get_block_by_cell_id(view, cell.id)

    view
    |> get_cell_element(cell.id)
    |> render_hook("update_block", %{
      "cell_id" => cell.id,
      "block_id" => block.id,
      "value" => value
    })
  end

  @doc """
  Simulates downgrade of a block (presing backspace from index 0 of first cell)
  """
  def downgrade_block(%View{} = view, %Block{} = block) do
    %Cell{} = cell = Enum.at(block.cells, 0)
    backspace(view, cell, 0)
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
  def paste_blocks(%View{} = view, %{cell_id: cell_id, index: index}) do
    view
    |> element(@model.selection)
    |> render_hook("paste_blocks", %{
      "cell_id" => cell_id,
      "index" => index
    })
  end

  def backspace(%View{} = view, %Block{} = block, :start_of_first_cell) do
    backspace(view, List.first(block.cells), 0)
  end

  def backspace(%View{} = view, %Cell{} = cell, index) when is_integer(index) do
    view
    |> get_cell_element(cell.id)
    |> render_hook("backspace", %{
      "cell_id" => cell.id,
      "index" => 0
    })
  end

  def cell_types(%Block{} = block) do
    Enum.map(block.cells, & &1.type)
  end

  def block_types(%View{} = view) do
    %Editor{} = editor = get_editor(view)
    Enum.map(editor.page.blocks, & &1.type)
  end

  def block_text(%View{} = view, index) when is_integer(index) do
    %Block{} = block = block_at(view, index)
    Editor.text(block)
  end
end
