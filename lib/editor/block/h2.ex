defmodule Editor.Block.H2 do
  @moduledoc """
  Holds logic specific to the h2 block
  """

  use Phoenix.LiveComponent
  use Phoenix.HTML

  alias Editor.Block
  alias Editor.Utils

  defstruct active: false, pre_caret: "", post_caret: "", id: Utils.new_id()

  @type t :: %__MODULE__{}

  def render(%{block: %__MODULE__{}} = assigns) do
    ~H"""
    <h2
      class="philtre__block"
      contenteditable
      data-block
      data-selected={@selected}
      id={@block.id}
      phx-hook="ContentEditable"
      phx-target={@myself}
    ><.content block={@block} /></h2>
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

  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  def handle_event("split_line", %{}, socket), do: {:noreply, socket}

  def handle_event("split_block", %{"pre" => pre_caret, "post" => post_caret}, socket) do
    %__MODULE__{} = block = socket.assigns.block
    old_block = %{block | active: false, pre_caret: pre_caret, post_caret: ""}

    new_block = %Block.P{
      id: Utils.new_id(),
      active: true,
      pre_caret: "",
      post_caret: post_caret
    }

    Editor.send_event(socket, "replace", %{block: block, with: [old_block, new_block]})
    {:noreply, socket}
  end

  def handle_event("update", %{"pre" => pre_caret, "post" => post_caret}, socket) do
    new_block = %{
      socket.assigns.block
      | active: true,
        pre_caret: pre_caret,
        post_caret: post_caret
    }

    Editor.send_event(socket, "replace", %{block: socket.assigns.block, with: [new_block]})

    {:noreply, socket}
  end

  def handle_event("backspace_from_start", %{"pre" => pre_caret, "post" => post_caret}, socket) do
    new_block = %Block.H3{
      id: Utils.new_id(),
      active: true,
      pre_caret: pre_caret,
      post_caret: post_caret
    }

    Editor.send_event(socket, "replace", %{block: socket.assigns.block, with: [new_block]})
    {:noreply, socket}
  end
end
