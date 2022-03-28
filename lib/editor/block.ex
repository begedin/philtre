defmodule Editor.Block do
  @moduledoc """
  Holds logic specific to the p block
  """

  use Phoenix.LiveComponent
  use Phoenix.HTML

  alias Editor.Engine
  alias Editor.Utils

  # struct

  defstruct pre_caret: "",
            post_caret: "",
            id: Utils.new_id(),
            type: "p",
            selection: nil

  @type t :: %__MODULE__{}

  # component

  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  def render(%{block: %__MODULE__{type: "p"}} = assigns) do
    ~H"""
    <p
      class="philtre__block"
      contenteditable
      data-block
      data-selected={@selected}
      id={@block.id}
      phx-hook="ContentEditable"
      phx-target={@myself}
    ><.content block={@block} /></p>
    """
  end

  def render(%{block: %__MODULE__{type: "pre"}} = assigns) do
    ~H"""
    <pre
      class="philtre__block"
      contenteditable
      data-block
      data-selected={@selected}
      id={@block.id}
      phx-hook="ContentEditable"
      phx-target={@myself}
    ><.content block={@block} /></pre>
    """
  end

  def render(%{block: %__MODULE__{type: "h1"}} = assigns) do
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

  def render(%{block: %__MODULE__{type: "h2"}} = assigns) do
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

  def render(%{block: %__MODULE__{type: "h3"}} = assigns) do
    ~H"""
    <h3
      class="philtre__block"
      contenteditable
      data-block
      data-selected={@selected}
      id={@block.id}
      phx-hook="ContentEditable"
      phx-target={@myself}
    ><.content block={@block} /></h3>
    """
  end

  def render(%{block: %__MODULE__{type: "blockquote"}} = assigns) do
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

  def render(%{block: %__MODULE__{type: "li"}} = assigns) do
    ~H"""
    <ul>
      <li
        class="philtre__block"
        contenteditable
        data-block
        data-selected={@selected}
        id={@block.id}
        phx-hook="ContentEditable"
        phx-target={@myself}
      ><.content block={@block} /></li></ul>
    """
  end

  defp content(%{block: %{selection: s} = block} = assigns) when is_binary(s) do
    content =
      Enum.join([
        block.pre_caret,
        Utils.selection_start(),
        block.selection,
        Utils.selection_end(),
        block.post_caret
      ])

    ~H"""
    <%= raw(content) %>

    """
  end

  defp content(%{block: %{selection: nil}} = assigns) do
    ~H"""
    <%= raw(@block.pre_caret <> @block.post_caret)  %>
    """
  end

  def handle_event(
        "update",
        %{"pre" => pre_caret, "selection" => selection, "post" => post_caret},
        socket
      ) do
    editor =
      Engine.update_block(socket.assigns.editor, socket.assigns.block, %{
        pre_caret: pre_caret,
        post_caret: post_caret,
        selection: selection
      })

    if editor !== socket.assigns.editor do
      send(self(), {:update, editor})
    end

    {:noreply, socket}
  end

  def handle_event("split_line", %{"pre" => pre, "post" => post}, socket) do
    editor =
      Engine.split_line(socket.assigns.editor, socket.assigns.block, %{pre: pre, post: post})

    if editor !== socket.assigns.editor do
      send(self(), {:update, editor})
    end

    {:noreply, socket}
  end

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
    editor = Engine.backspace_from_start(socket.assigns.editor, socket.assigns.block)

    if editor !== socket.assigns.editor do
      send(self(), {:update, editor})
    end

    {:noreply, socket}
  end
end
