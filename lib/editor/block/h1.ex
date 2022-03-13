defmodule Editor.Block.H1 do
  @moduledoc """
  Holds logic specific to the h1 block
  """

  use Phoenix.LiveComponent
  use Phoenix.HTML

  alias Editor.Block
  alias Editor.Engine
  alias Editor.Utils

  defstruct active: false, pre_caret: "", post_caret: "", id: Utils.new_id()

  @type t :: %__MODULE__{}

  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  def render(%{block: %__MODULE__{}} = assigns) do
    ~H"""
    <h1
      class="philtre__block"
      contenteditable
      data-block
      data-selected={@selected}
      id={@block.id}
      phx-hook="ContentEditable"
      phx-target={@myself}
    ><.content block={@block} /></h1>
    """
  end

  defp content(%{block: %{active: true}} = assigns) do
    ~H"""
    <%= raw(@block.pre_caret <> Utils.caret() <> @block.post_caret)  %>
    """
  end

  defp content(%{block: %{active: false}} = assigns) do
    ~H"""
    <%= raw(@block.pre_caret <> @block.post_caret)  %>
    """
  end

  def handle_event("update", %{"pre" => pre, "post" => post}, socket) do
    editor =
      Engine.update_block(socket.assigns.editor, socket.assigns.block, %{pre: pre, post: post})

    if editor !== socket.assigns.editor do
      send(self(), {:update, editor})
    end

    {:noreply, socket}
  end

  def handle_event("split_line", %{"pre" => _, "post" => _}, socket), do: {:noreply, socket}

  def handle_event("split_block", %{"pre" => pre, "post" => post}, socket) do
    editor =
      Engine.split_block(socket.assigns.editor, socket.assigns.block, %{pre: pre, post: post})

    if editor !== socket.assigns.editor do
      send(self(), {:update, editor})
    end

    {:noreply, socket}
  end

  def handle_event("paste_blocks", %{"pre" => pre, "post" => post}, socket) do
    editor = Engine.paste(socket.assigns.editor, socket.assigns.block, %{pre: pre, post: post})

    if editor !== socket.assigns.editor do
      send(self(), {:update, editor})
    end

    {:noreply, socket}
  end

  def handle_event("backspace_from_start", _, socket) do
    editor = Engine.convert(socket.assigns.editor, socket.assigns.block, Block.H2)

    if editor !== socket.assigns.editor do
      send(self(), {:update, editor})
    end

    {:noreply, socket}
  end
end
