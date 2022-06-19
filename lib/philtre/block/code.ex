defmodule Philtre.Block.Code do
  @moduledoc """
  Elixir-side implementation of the code-type block

  This block is used to write code in a synthax-highlighted UI. The frontend
  aspect of it is implemented in `hooks/Code.ts`
  """
  use Phoenix.Component

  alias Philtre.Block.ContentEditable
  alias Philtre.Editor
  alias Philtre.Editor.Utils

  require Logger

  defstruct id: nil, content: "", language: "elixir", focused: false

  def render(assigns) do
    # data-language is used to get the language in the frontend hook, which is
    # then used by the frontend-based code-highlighting library
    ~H"""
    <div
      class="philtre__code"
      data-block
      data-language="elixir"
      id={@block.id}
      phx-hook="Code"
      phx-update="ignore"
      phx-target={@myself}
    >
      <pre><code class="philtre__code__highlighted"><%= @block.content %></code></pre>
      <textarea
        class="philtre__code__editable"
        spellcheck="false"
        autofocus={@block.focused}
        rows={rows(@block.content)}><%= @block.content %></textarea>
    </div>
    """
  end

  defp rows(content) when is_binary(content) do
    content
    |> String.split("\n")
    |> Enum.count()
  end

  def html(%__MODULE__{} = table) do
    %{block: table}
    |> read_only()
    |> Phoenix.HTML.html_escape()
    |> Phoenix.HTML.safe_to_string()
  end

  def read_only(%{block: _} = assigns) do
    ~H"<pre><%= @block.content %></pre>"
  end

  def handle_event("update", %{"value" => value}, socket) do
    new_block = %{socket.assigns.block | content: value}
    index = Enum.find_index(socket.assigns.editor.blocks, &(&1.id === new_block.id))
    new_blocks = List.replace_at(socket.assigns.editor.blocks, index, new_block)
    new_editor = %{socket.assigns.editor | blocks: new_blocks}

    send(self(), {:update, new_editor})

    {:noreply, socket}
  end

  def handle_event("add_block", %{} = params, socket) do
    Logger.debug("add_block: #{inspect(params)}")

    %__MODULE__{} = block = socket.assigns.block

    cell = ContentEditable.Cell.new()

    new_block = %ContentEditable{
      id: Utils.new_id(),
      type: "p",
      cells: [cell],
      selection: ContentEditable.Selection.new_start_of(cell)
    }

    new_editor = Editor.replace_block(socket.assigns.editor, block, [block, new_block])

    send(self(), {:update, new_editor})

    {:noreply, socket}
  end
end
