defmodule Editor do
  @moduledoc """
  Shared component used for both creation and editing of an article.
  """
  use PhiltreWeb, :live_component

  alias Editor.Block
  alias Editor.Cell
  alias Editor.Operations
  alias Editor.Serializer
  alias Editor.Utils

  defstruct active_cell_id: nil,
            blocks: [],
            clipboard: nil,
            cursor_index: nil,
            id: nil,
            selected_blocks: []

  @type t :: %__MODULE__{}

  def new do
    %__MODULE__{
      id: Utils.new_id(),
      active_cell_id: nil,
      blocks: [
        %Block{
          type: "h1",
          id: Utils.new_id(),
          cells: [
            %Cell{
              id: Utils.new_id(),
              type: "span",
              content: "This is the title of your page"
            }
          ]
        }
      ]
    }
  end

  @spec update(%{optional(:editor) => t()}, LiveView.Socket.t()) :: {:ok, LiveView.Socket.t()}
  def update(%{editor: %__MODULE__{} = editor}, socket) do
    socket = assign(socket, editor: editor)
    {:ok, socket}
  end

  def update(%{}, socket) do
    {:ok, assign(socket, :editor, new())}
  end

  @spec handle_event(String.t(), map, LiveView.Socket.t()) :: {:noreply, LiveView.Socket.t()}

  def handle_event("newline", %{"cell_id" => cell_id, "index" => index}, socket) do
    editor = Operations.newline(socket.assigns.editor, cell_id, index)
    send(self(), {:update, editor})
    {:noreply, socket}
  end

  def handle_event("update_block", %{"cell_id" => cell_id, "value" => value}, socket) do
    editor = Operations.update_block(socket.assigns.editor, cell_id, value)
    send(self(), {:update, editor})
    {:noreply, socket}
  end

  def handle_event("backspace", %{"cell_id" => cell_id}, socket) do
    editor = Operations.backspace(socket.assigns.editor, cell_id)
    send(self(), {:update, editor})
    {:noreply, socket}
  end

  def handle_event("select_blocks", %{"block_ids" => block_ids}, socket)
      when is_list(block_ids) do
    send(self(), {:update, %{socket.assigns.editor | selected_blocks: block_ids}})
    {:noreply, socket}
  end

  def handle_event("copy_blocks", %{"block_ids" => block_ids}, socket)
      when is_list(block_ids) do
    blocks = Enum.filter(socket.assigns.editor.blocks, &(&1.id in block_ids))
    send(self(), {:update, %{socket.assigns.editor | clipboard: blocks}})
    {:noreply, socket}
  end

  def handle_event("paste_blocks", %{"cell_id" => cell_id, "index" => index}, socket) do
    %Editor{} = editor = socket.assigns.editor

    if editor.clipboard != nil do
      new_editor = Operations.paste_blocks(editor, editor.clipboard, cell_id, index)
      send(self(), {:update, new_editor})
    end

    {:noreply, socket}
  end

  defdelegate serialize(editor), to: Serializer
  defdelegate normalize(editor), to: Serializer
  defdelegate text(editor), to: Serializer
  defdelegate html(editor), to: Serializer
end
