defmodule Philtre.Table do
  @moduledoc """
  Implementation for a table section/component of the editor

  To add to editor, use `/table`.

  The current implementation starts of with a single cell, to which additional
  rows and cells can be added and removed from.
  """
  use Phoenix.LiveComponent

  defstruct id: nil, rows: [[""]]

  def render(assigns) do
    cell_count = cell_count(assigns[:block])

    ~H"""
    <table>
      <tr>
        <%= for column_index <- 0..(cell_count - 1) do %>
          <th>
            <button
              disabled={cell_count <= 1}
              phx-click="remove_column"
              phx-value-index={column_index}
              phx-target={@myself}>-</button>
          </th>
        <% end %>
      </tr>
      <%= for {row, row_index} <- Enum.with_index(@block.rows) do %>
        <tr>
          <%= for {cell, cell_index} <- Enum.with_index(row) do %>
            <td>
              <form phx-change="update_cell" phx-target={@myself} >
                <input type="hidden" name="cell_index" value={cell_index} />
                <input type="hidden" name="row_index" value={row_index} />
                <input
                  name="cell"
                  type="text"
                  value={cell}
                />
              </form>
            </td>
          <% end %>
          <td><button phx-click="add_column" phx-target={@myself}>+</button></td>
          <td>
            <button
              disabled={Enum.count(@block.rows) <= 1}
              phx-click="remove_row"
              phx-value-index={row_index}
              phx-target={@myself}>-</button>
          </td>
        </tr>
      <% end %>
      <tr>
        <td>
          <button phx-click="add_row" phx-target={@myself}>+</button>
        </td>
      </tr>
    </table>
    """
  end

  def read_only(%{} = assigns) do
    ~H"""
    <table>
      <%= for row <- @block.rows do %>
        <tr>
          <%= for cell <- row do %>
            <td><%= cell %></td>
          <% end %>
        </tr>
      <% end %>
    </table>
    """
  end

  def html(%__MODULE__{} = table) do
    %{block: table}
    |> read_only()
    |> Phoenix.HTML.html_escape()
    |> Phoenix.HTML.safe_to_string()
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
    %__MODULE__{rows: rows} = table = socket.assigns.block
    new_rows = Enum.map(rows, &(&1 ++ [""]))

    new_table = %{table | rows: new_rows}

    %{blocks: blocks} = editor = socket.assigns.editor

    index = Enum.find_index(blocks, &(&1.id === table.id))
    new_editor = %{editor | blocks: List.replace_at(blocks, index, new_table)}

    send(self(), {:update, new_editor})

    {:noreply, socket}
  end

  def handle_event("remove_column", %{"index" => index}, socket) do
    index = String.to_integer(index)
    %__MODULE__{rows: rows} = table = socket.assigns.block

    new_rows =
      Enum.map(rows, fn columns ->
        columns
        |> Enum.with_index()
        |> Enum.reject(fn {_row, row_index} -> row_index === index end)
        |> Enum.map(fn {row, _row_index} -> row end)
      end)

    new_table = %{table | rows: new_rows}

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
        %{"cell" => content, "cell_index" => cell_index, "row_index" => row_index},
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

  defp cell_count(%__MODULE__{rows: []}), do: 1
  defp cell_count(%__MODULE__{rows: [row | _]}), do: Enum.count(row)
end
