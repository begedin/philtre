defmodule Editor do
  @moduledoc """
  Shared component used for both creation and editing of an article.
  """
  use PhiltreWeb, :live_component

  alias Editor.Block
  alias Editor.Cell
  alias Editor.Operations
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

  def handle_event(
        "newline",
        %{"cell_id" => cell_id, "index" => index},
        socket
      ) do
    editor = Operations.newline(socket.assigns.editor, cell_id, index)
    send(self(), {:update, editor})
    {:noreply, socket}
  end

  def handle_event(
        "update_block",
        %{"cell_id" => cell_id, "value" => value},
        socket
      ) do
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
      new_editor = paste_blocks(editor, cell_id, index)
      send(self(), {:update, new_editor})
    end

    {:noreply, socket}
  end

  defp paste_blocks(%Editor{} = editor, cell_id, index) do
    %Editor{} = new_editor = Operations.paste_blocks(editor, editor.clipboard, cell_id, index)

    old_block_ids = Enum.map(editor.blocks, & &1.id)
    new_block_ids = Enum.map(new_editor.blocks, & &1.id)

    clone_ids = Enum.filter(new_block_ids, &(&1 not in old_block_ids))

    %{new_editor | selected_blocks: clone_ids}
  end

  def html(%Editor{} = editor) do
    Enum.map_join(editor.blocks, &html/1)
  end

  def html(%Editor.Block{} = block) do
    cell_html = Enum.map_join(block.cells, &html/1)
    "<#{block.type}>#{cell_html}</#{block.type}>"
  end

  def html(%Editor.Cell{} = cell) do
    "<#{cell.type}>#{cell.content}</#{cell.type}>"
  end

  def text(%Editor{} = editor) do
    Enum.map_join(editor.blocks, &text/1)
  end

  def text(%Editor.Block{} = block) do
    Enum.map_join(block.cells, &text/1)
  end

  def text(%Editor.Cell{content: content}), do: content

  def serialize(%Editor{} = editor) do
    editor
    |> Map.from_struct()
    |> Map.put(:blocks, Enum.map(editor.blocks, &serialize/1))
  end

  def serialize(%Editor.Block{} = block) do
    block
    |> Map.from_struct()
    |> Map.put(:cells, Enum.map(block.cells, &serialize/1))
  end

  def serialize(%Editor.Cell{} = cell) do
    Map.from_struct(cell)
  end

  def normalize(%{"blocks" => blocks}) when is_list(blocks) do
    normalize(%{blocks: blocks})
  end

  def normalize(%{blocks: blocks}) when is_list(blocks) do
    %Editor{blocks: Enum.map(blocks, &normalize/1)}
  end

  def normalize(%{"cells" => cells, "id" => id, "type" => type})
      when is_list(cells) and is_binary(id) and is_binary(type) do
    normalize(%{cells: cells, id: id, type: type})
  end

  def normalize(%{cells: cells, id: id, type: type})
      when is_list(cells) and is_binary(id) and is_binary(type) do
    %Editor.Block{
      id: id,
      type: type,
      cells: Enum.map(cells, &normalize/1)
    }
  end

  def normalize(%{"content" => content, "id" => id, "type" => type})
      when is_binary(content) and is_binary(id) and is_binary(type) do
    normalize(%{content: content, id: id, type: type})
  end

  def normalize(%{content: content, id: id, type: type})
      when is_binary(content) and is_binary(id) and is_binary(type) do
    %Editor.Cell{id: id, type: type, content: content}
  end
end
