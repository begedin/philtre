defmodule Philtre.Block.Code do
  @moduledoc """
  Elixir-side implementation of the code-type block

  This block is used to write code in a synthax-highlighted UI. The frontend
  aspect of it is implemented in `hooks/Code.ts`
  """
  use Phoenix.LiveComponent

  defstruct id: nil, content: "", language: "elixir"

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
end
