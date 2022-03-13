defmodule Editor.Block.Blockquote do
  @moduledoc """
  Holds logic specific to the BLOCKQUOTE block
  """

  use Phoenix.LiveComponent
  use Phoenix.HTML

  alias Editor.Block
  alias Editor.BlockEngine
  alias Editor.Utils

  defstruct active: false, pre_caret: "", post_caret: "", id: Utils.new_id()

  @type t :: %__MODULE__{}

  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  def render(%{block: %__MODULE__{}} = assigns) do
    ~H"""
    <blockquote
      class="philtre__block"
      contenteditable
      data-block
      data-selected={@selected}
      id={@block.id}
      phx-hook="ContentEditable"
      phx-target={@myself}
    ><.content block={@block} /></blockquote>
    """
  end

  defp content(%{block: %{active: true}} = assigns) do
    ~H"""
    <%= raw(@block.pre_caret <> Utils.caret() <> @block.post_caret)  %>
    """
  end

  defp content(%{block: %{}} = assigns) do
    ~H"""
    <%= raw(@block.pre_caret <> @block.post_caret)  %>
    """
  end

  def handle_event("update", %{"pre" => pre_caret, "post" => post_caret}, socket) do
    new_block = BlockEngine.update(socket.assigns.block, pre_caret, post_caret)
    Editor.send_event(socket, "replace", %{block: socket.assigns.block, with: [new_block]})

    {:noreply, socket}
  end

  def handle_event("split_line", %{"pre" => pre_caret, "post" => post_caret}, socket) do
    new_block = BlockEngine.split_line(socket.assigns.block, pre_caret, post_caret)
    Editor.send_event(socket, "replace", %{block: socket.assigns.block, with: new_block})

    {:noreply, socket}
  end

  def handle_event("split_block", %{"pre" => pre_caret, "post" => post_caret}, socket) do
    new_blocks = BlockEngine.split_block(socket.assigns.block, pre_caret, post_caret)
    Editor.send_event(socket, "replace", %{block: socket.assigns.block, with: [new_blocks]})

    {:noreply, socket}
  end

  def handle_event("backspace_from_start", %{"pre" => pre_caret, "post" => post_caret}, socket) do
    new_block = BlockEngine.convert(socket.assigns.block, pre_caret, post_caret, Block.P)
    Editor.send_event(socket, "replace", %{block: socket.assigns.block, with: [new_block]})

    {:noreply, socket}
  end
end
