defmodule EditorTest.Wrapper do
  @moduledoc """
  Defines a view and a set of utility functions to test how the editor
  component interacts with the view.

  Editor tests should only ever interact with the component via functions defined here.
  """
  use Phoenix.LiveView

  import Phoenix.LiveView.Helpers
  import Phoenix.LiveViewTest

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

  @doc """
  Retrieves block at specified index
  """
  def block_at(%View{} = view, index) do
    %Editor{blocks: blocks} = get_editor(view)
    Enum.at(blocks, index)
  end

  @doc """
  Retrieves block by specified id
  """
  def get_block_by_id(%View{} = view, block_id) do
    %Editor{blocks: blocks} = get_editor(view)
    Enum.find(blocks, &(&1.id === block_id))
  end

  @doc """
  Retrieve cursor index
  """
  def cursor_index(%View{} = view) do
    %Editor{} = editor = get_editor(view)
    %_{} = block = Enum.find(editor.blocks, &(&1.selection != nil))
    String.length(block.pre_caret)
  end

  @doc """
  Sends newline command at the location
  """
  def trigger_split_block(%View{} = view, :end_of_page) do
    %Editor{} = editor = get_editor(view)
    trigger_split_block(view, List.last(editor.blocks), :end)
  end

  @model %{selection: "[id^=editor__selection__]"}

  @doc """
  Sends newline command at the location
  """
  def trigger_split_block(%View{} = view, %_{pre_caret: _, post_caret: _} = block, :end) do
    trigger_split_block(view, block, %{pre: block.pre_caret <> block.post_caret, post: ""})
  end

  def trigger_split_block(%View{} = view, index, %{pre: pre, post: post})
      when is_integer(index) do
    trigger_split_block(view, block_at(view, index), %{pre: pre, post: post})
  end

  def trigger_split_block(%View{} = view, %_{} = block, %{pre: pre, post: post}) do
    view
    |> element("##{block.id}")
    |> render_hook("split_block", %{"pre" => pre, "post" => post})
  end

  @doc """
  Updates cell at specified location with specified value
  """
  def trigger_update(%View{} = view, index, %{pre: pre, selection: selection, post: post})
      when is_integer(index) do
    trigger_update(view, block_at(view, index), %{pre: pre, selection: selection, post: post})
  end

  def trigger_update(%View{} = view, %_{} = block, %{pre: pre, selection: selection, post: post}) do
    view
    |> element("##{block.id}")
    |> render_hook("update", %{"pre" => pre, "selection" => selection, "post" => post})
  end

  @doc """
  Simulates downgrade of a block (presing backspace from index 0 of first cell)
  """
  def trigger_backspace_from_start(%View{} = view, index) when is_integer(index) do
    trigger_backspace_from_start(view, block_at(view, index))
  end

  def trigger_backspace_from_start(%View{} = view, %_{} = block) do
    view
    |> element("##{block.id}")
    |> render_hook("backspace_from_start", %{
      "pre" => "",
      "post" => block.pre_caret <> block.post_caret
    })
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
  def paste_blocks(%View{} = view, index, %{pre: pre, post: post}) when is_integer(index) do
    paste_blocks(view, block_at(view, index), %{pre: pre, post: post})
  end

  def paste_blocks(%View{} = view, %_{} = block, %{pre: pre, post: post}) do
    view
    |> element("##{block.id}")
    |> render_hook("paste_blocks", %{"pre" => pre, "post" => post})
  end

  def block_text(%View{} = view, index) when is_integer(index) do
    %_{} = block = block_at(view, index)
    Editor.text(block)
  end
end
