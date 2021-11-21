defmodule Editor do
  @moduledoc """
  Shared component used for both creation and editing of an article.
  """
  use PhiltreWeb, :live_component

  @spec update(
          %{optional(:slug) => String.t()},
          LiveView.Socket.t()
        ) :: {:ok, LiveView.Socket.t()}
  def update(%{page: page}, socket) do
    {:ok, assign(socket, :page, page)}
  end

  def update(%{}, socket) do
    {:ok, assign(socket, :page, Editor.Page.new())}
  end

  @spec handle_event(String.t(), map, LiveView.Socket.t()) :: {:noreply, LiveView.Socket.t()}

  def handle_event(
        "insert_block",
        %{"cell_id" => cell_id, "block_id" => block_id, "index" => index},
        socket
      ) do
    page = Editor.Page.insert_block(socket.assigns.page, block_id, cell_id, index)
    send(self(), {:updated_page, page})
    {:noreply, socket}
  end

  def handle_event(
        "update_block",
        %{"cell_id" => cell_id, "block_id" => block_id, "value" => value},
        socket
      ) do
    page = Editor.Page.update_block(socket.assigns.page, block_id, cell_id, value)
    send(self(), {:updated_page, page})
    {:noreply, socket}
  end

  def handle_event("backspace", %{"cell_id" => cell_id, "block_id" => block_id}, socket) do
    page = Editor.Page.backspace(socket.assigns.page, block_id, cell_id)
    send(self(), {:updated_page, page})
    {:noreply, socket}
  end

  def html(%Editor.Page{} = page) do
    page.blocks |> Enum.map(&html/1) |> Enum.join("")
  end

  def html(%Editor.Block{} = block) do
    cell_html = block.cells |> Enum.map(&html/1) |> Enum.join("")
    "<#{block.type}>#{cell_html}</#{block.type}>"
  end

  def html(%Editor.Cell{} = cell) do
    "<#{cell.type}>#{cell.content}</#{cell.type}>"
  end

  def text(%Editor.Page{} = page) do
    page.blocks
    |> Enum.map(&text/1)
    |> Enum.join("")
  end

  def text(%Editor.Block{} = block) do
    block.cells |> Enum.map(&text/1) |> Enum.join("")
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
