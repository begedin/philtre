defmodule Philtre.Block.Table do
  @moduledoc """
  Implementation for a table section/component of the editor

  To add to editor, use `/table`.

  The current implementation starts of with a single cell, to which additional
  rows and cells can be added and removed from.
  """
  use Phoenix.Component

  alias Philtre.Block
  alias Philtre.Block.ContentEditable.Selection
  alias Philtre.Editor.Utils

  @behaviour Block

  defstruct id: nil, header_rows: [[""]], rows: [[""]]

  @impl Block
  def id(%__MODULE__{id: id}), do: id

  @impl Block
  def type(%__MODULE__{}), do: "table"

  @impl Block
  def data(%__MODULE__{header_rows: header_rows, rows: rows}) do
    %{"header_rows" => header_rows, "rows" => rows}
  end

  @impl Block
  def normalize(id, %{"header_rows" => header_rows, "rows" => rows}) do
    %__MODULE__{
      id: id,
      header_rows: header_rows,
      rows: rows
    }
  end

  @impl Block
  def render_live(assigns) do
    ~H"""
    <div class="philtre__table" data-block>
      <table>
        <thead>
          <.head {assigns} />
        </thead>
        <tbody>
          <.body {assigns} />
        </tbody>
      </table>
      <button title="Add a column" phx-click="add_column" phx-target={@myself}>+</button>
      <button title="Add a row" phx-click="add_row" phx-target={@myself}>+</button>
    </div>
    """
  end

  attr(:block, __MODULE__, required: true)

  defp head(assigns) do
    assigns = assign(assigns, :disabled, cell_count(assigns.block) <= 1)

    ~H"""
    <%= for {row, row_index} <- Enum.with_index(@block.header_rows) do %>
      <tr>
        <%= for {cell, cell_index} <- Enum.with_index(row) do %>
          <th>
            <!-- each column of the first header row gets the remove column button -->
            <button
              if={row_index == 0}
              disabled={@disabled}
              title="Remove this column"
              phx-click="remove_column"
              phx-value-index={cell_index}
              phx-target={@myself}
            >
              -
            </button>

            <.cell {assigns} cell={cell} cell_index={cell_index} cell_type="head" row_index={row_index} />
          </th>
        <% end %>
      </tr>
    <% end %>
    """
  end

  defp body(assigns) do
    ~H"""
    <%= for {row, row_index} <- Enum.with_index(@block.rows) do %>
      <tr>
        <% cell_count = Enum.count(row) %>
        <%= for {cell, cell_index} <- Enum.with_index(row) do %>
          <td>
            <.cell {assigns} cell={cell} cell_index={cell_index} cell_type="body" row_index={row_index} />
            <!-- last column of a row gets the remove row button -->
            <%= if cell_index == cell_count - 1 do %>
              <button
                disabled={Enum.count(@block.rows) <= 1}
                title="Remove this row"
                phx-click="remove_row"
                phx-value-index={row_index}
                phx-target={@myself}
              >
                -
              </button>
            <% end %>
          </td>
        <% end %>
      </tr>
    <% end %>
    """
  end

  attr(:cell, :string, required: true)
  attr(:cell_index, :integer, required: true)

  defp cell(assigns) do
    rows =
      assigns.cell
      |> String.split("\n")
      |> Enum.map(fn line ->
        line
        |> String.codepoints()
        |> Enum.chunk_every(50)
        |> Enum.map(&Enum.join/1)
      end)
      |> List.flatten()

    height = rows |> Enum.count() |> Kernel.max(1)

    width =
      rows
      |> Enum.reject(&(&1 == ""))
      |> Enum.map(&String.length/1)
      |> Enum.max(fn -> 1 end)
      |> Kernel.max(1)

    assigns = assign(assigns, width: width, height: height)

    ~H"""
    <form phx-change="update_cell" phx-target={@myself}>
      <input type="hidden" name="cell_type" value={@cell_type} />
      <input type="hidden" name="cell_index" value={@cell_index} />
      <input type="hidden" name="row_index" value={@row_index} />
      <textarea name="cell" type="text" rows={@height} cols={@width}><%= @cell %></textarea>
    </form>
    """
  end

  @impl Block
  def render_static(%{} = assigns) do
    ~H"""
    <table>
      <thead>
        <%= for row <- @block.header_rows do %>
          <tr>
            <%= for cell <- row do %>
              <th><%= cell %></th>
            <% end %>
          </tr>
        <% end %>
      </thead>
      <tbody>
        <%= for row <- @block.rows do %>
          <tr>
            <%= for cell <- row do %>
              <td><%= cell %></td>
            <% end %>
          </tr>
        <% end %>
      </tbody>
    </table>
    """
  end

  def handle_event("add_row", %{}, socket) do
    %__MODULE__{rows: rows} = table = socket.assigns.block

    new_row = List.duplicate("", cell_count(table))

    new_table = %{table | rows: rows ++ [new_row]}

    %{blocks: blocks} = editor = socket.assigns.editor

    index = Enum.find_index(blocks, &(&1.id === table.id))
    new_editor = %{editor | blocks: List.replace_at(blocks, index, new_table)}

    send(self(), {:update, new_editor})

    {:noreply, socket}
  end

  def handle_event("add_column", %{}, socket) do
    %__MODULE__{rows: rows, header_rows: header_rows} = table = socket.assigns.block
    new_rows = Enum.map(rows, &(&1 ++ [""]))
    new_header_rows = Enum.map(header_rows, &(&1 ++ [""]))

    new_table = %{table | rows: new_rows, header_rows: new_header_rows}

    %{blocks: blocks} = editor = socket.assigns.editor

    index = Enum.find_index(blocks, &(&1.id === table.id))
    new_editor = %{editor | blocks: List.replace_at(blocks, index, new_table)}

    send(self(), {:update, new_editor})

    {:noreply, socket}
  end

  def handle_event("remove_column", %{"index" => index}, socket) do
    index = String.to_integer(index)
    %__MODULE__{rows: rows, header_rows: header_rows} = table = socket.assigns.block

    new_rows =
      Enum.map(rows, fn columns ->
        columns
        |> Enum.with_index()
        |> Enum.reject(fn {_row, row_index} -> row_index === index end)
        |> Enum.map(fn {row, _row_index} -> row end)
      end)

    new_header_rows =
      Enum.map(header_rows, fn columns ->
        columns
        |> Enum.with_index()
        |> Enum.reject(fn {_row, row_index} -> row_index === index end)
        |> Enum.map(fn {row, _row_index} -> row end)
      end)

    new_table = %{table | rows: new_rows, header_rows: new_header_rows}

    %{blocks: blocks} = editor = socket.assigns.editor
    index = Enum.find_index(blocks, &(&1.id === table.id))
    new_editor = %{editor | blocks: List.replace_at(blocks, index, new_table)}

    send(self(), {:update, new_editor})

    {:noreply, socket}
  end

  def handle_event("remove_row", %{"index" => index}, socket) do
    index = String.to_integer(index)
    %__MODULE__{rows: rows} = table = socket.assigns.block

    new_rows = List.delete_at(rows, index)
    new_table = %{table | rows: new_rows}

    %{blocks: blocks} = editor = socket.assigns.editor
    index = Enum.find_index(blocks, &(&1.id === table.id))
    new_editor = %{editor | blocks: List.replace_at(blocks, index, new_table)}

    send(self(), {:update, new_editor})

    {:noreply, socket}
  end

  def handle_event(
        "update_cell",
        %{
          "cell" => content,
          "cell_index" => cell_index,
          "row_index" => row_index,
          "cell_type" => "body"
        },
        socket
      ) do
    cell_index = String.to_integer(cell_index)
    row_index = String.to_integer(row_index)

    %__MODULE__{rows: rows} = table = socket.assigns.block

    row = Enum.at(rows, row_index)
    new_row = List.replace_at(row, cell_index, content)
    new_rows = List.replace_at(rows, row_index, new_row)
    new_table = %{table | rows: new_rows}

    %{blocks: blocks} = editor = socket.assigns.editor
    index = Enum.find_index(blocks, &(&1.id === table.id))
    new_editor = %{editor | blocks: List.replace_at(blocks, index, new_table)}

    send(self(), {:update, new_editor})

    {:noreply, socket}
  end

  def handle_event(
        "update_cell",
        %{
          "cell" => content,
          "cell_index" => cell_index,
          "row_index" => row_index,
          "cell_type" => "head"
        },
        socket
      ) do
    cell_index = String.to_integer(cell_index)
    row_index = String.to_integer(row_index)

    %__MODULE__{header_rows: rows} = table = socket.assigns.block

    row = Enum.at(rows, row_index)
    new_row = List.replace_at(row, cell_index, content)
    new_rows = List.replace_at(rows, row_index, new_row)
    new_table = %{table | header_rows: new_rows}

    %{blocks: blocks} = editor = socket.assigns.editor
    index = Enum.find_index(blocks, &(&1.id === table.id))
    new_editor = %{editor | blocks: List.replace_at(blocks, index, new_table)}

    send(self(), {:update, new_editor})

    {:noreply, socket}
  end

  defp cell_count(%__MODULE__{rows: []}), do: 1
  defp cell_count(%__MODULE__{rows: [row | _]}), do: Enum.count(row)

  @impl Block
  def transform(%Block.ContentEditable{} = block) do
    %__MODULE__{id: Utils.new_id(), rows: [Enum.map(block.cells, &String.trim(&1.text))]}
  end

  @impl Block
  def set_selection(%__MODULE__{} = block, %Selection{}), do: block

  @impl Block
  def reduce(%__MODULE__{} = block), do: block

  @impl Block
  def cells(%__MODULE__{}), do: []
end
