defmodule Editor do
  @moduledoc """
  Shared component used for both creation and editing of an article.
  """
  use PhiltreWeb, :live_component

  defstruct id: nil, page: Editor.Page.new(), selected_blocks: [], clipboard: nil

  @type t :: %__MODULE__{}

  def new do
    %__MODULE__{id: Editor.Utils.new_id(), page: Editor.Page.new()}
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
        "insert_block",
        %{"cell_id" => cell_id, "index" => index},
        socket
      ) do
    page = Editor.Page.insert_block(socket.assigns.editor.page, cell_id, index)
    send(self(), {:update, %{socket.assigns.editor | page: page}})
    {:noreply, socket}
  end

  def handle_event(
        "update_block",
        %{"cell_id" => cell_id, "value" => value},
        socket
      ) do
    page = Editor.Page.update_block(socket.assigns.editor.page, cell_id, value)
    send(self(), {:update, %{socket.assigns.editor | page: page}})
    {:noreply, socket}
  end

  def handle_event("backspace", %{"cell_id" => cell_id}, socket) do
    page = Editor.Page.backspace(socket.assigns.editor.page, cell_id)
    send(self(), {:update, %{socket.assigns.editor | page: page}})
    {:noreply, socket}
  end

  def handle_event("select_blocks", %{"block_ids" => block_ids}, socket)
      when is_list(block_ids) do
    selected_blocks = Enum.dedup(socket.assigns.editor.selected_blocks ++ block_ids)
    send(self(), {:update, %{socket.assigns.editor | selected_blocks: selected_blocks}})
    {:noreply, socket}
  end

  def handle_event("copy_blocks", %{"block_ids" => block_ids}, socket)
      when is_list(block_ids) do
    blocks = Enum.filter(socket.assigns.editor.page.blocks, &(&1.id in block_ids))
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
    %Editor.Page{} =
      page = Editor.Page.paste_blocks(editor.page, editor.clipboard, cell_id, index)

    old_block_ids = Enum.map(editor.page.blocks, & &1.id)
    new_block_ids = Enum.map(page.blocks, & &1.id)

    clone_ids = Enum.filter(new_block_ids, &(&1 not in old_block_ids))

    %{editor | page: page, selected_blocks: clone_ids}
  end

  def html(%Editor.Page{} = page) do
    Enum.map_join(page.blocks, &html/1)
  end

  def html(%Editor.Block{} = block) do
    cell_html = Enum.map_join(block.cells, &html/1)
    "<#{block.type}>#{cell_html}</#{block.type}>"
  end

  def html(%Editor.Cell{} = cell) do
    "<#{cell.type}>#{cell.content}</#{cell.type}>"
  end

  def text(%Editor.Page{} = page) do
    Enum.map_join(page.blocks, &text/1)
  end

  def text(%Editor.Block{} = block) do
    Enum.map_join(block.cells, &text/1)
  end

  def text(%Editor.Cell{content: content}), do: content

  def serialize(%Editor.Page{} = page) do
    page
    |> Map.from_struct()
    |> Map.put(:blocks, Enum.map(page.blocks, &serialize/1))
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
    %Editor.Page{
      blocks: Enum.map(blocks, &normalize/1)
    }
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
