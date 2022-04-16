defmodule Editor.Block do
  @moduledoc """
  Holds logic specific to the p block
  """

  use Phoenix.LiveComponent
  use Phoenix.HTML

  alias Editor.Engine
  alias Editor.Utils

  require Logger

  # struct

  defstruct cells: [],
            id: Utils.new_id(),
            type: "p",
            selection: %{}

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
      id={@block.id}
      phx-hook="ContentEditable"
      phx-target={@myself}
      data-selected={@selected}
      data-selection-start-id={@block.selection[:start_id]}
      data-selection-start-offset={@block.selection[:start_offset]}
      data-selection-end-id={@block.selection[:end_id]}
      data-selection-end-offset={@block.selection[:end_offset]}
    ><.content block={@block} /></p>
    """
  end

  def render(%{block: %__MODULE__{type: "pre"}} = assigns) do
    ~H"""
    <pre
      class="philtre__block"
      contenteditable
      id={@block.id}
      phx-hook="ContentEditable"
      phx-target={@myself}
      data-block
      data-selected={@selected}
      data-selection-start-id={@block.selection[:start_id]}
      data-selection-start-offset={@block.selection[:start_offset]}
      data-selection-end-id={@block.selection[:end_id]}
      data-selection-end-offset={@block.selection[:end_offset]}
    ><.content block={@block} /></pre>
    """
  end

  def render(%{block: %__MODULE__{type: "h1"}} = assigns) do
    ~H"""
    <h1
      class="philtre__block"
      contenteditable
      id={@block.id}
      phx-hook="ContentEditable"
      phx-target={@myself}
      data-block
      data-selected={@selected}
      data-selection-start-id={@block.selection[:start_id]}
      data-selection-start-offset={@block.selection[:start_offset]}
      data-selection-end-id={@block.selection[:end_id]}
      data-selection-end-offset={@block.selection[:end_offset]}
    ><.content block={@block} /></h1>
    """
  end

  def render(%{block: %__MODULE__{type: "h2"}} = assigns) do
    ~H"""
    <h2
      class="philtre__block"
      contenteditable
      id={@block.id}
      phx-hook="ContentEditable"
      phx-target={@myself}
      data-block
      data-selected={@selected}
      data-selection-start-id={@block.selection[:start_id]}
      data-selection-start-offset={@block.selection[:start_offset]}
      data-selection-end-id={@block.selection[:end_id]}
      data-selection-end-offset={@block.selection[:end_offset]}
    ><.content block={@block} /></h2>
    """
  end

  def render(%{block: %__MODULE__{type: "h3"}} = assigns) do
    ~H"""
    <h3
      class="philtre__block"
      contenteditable
      id={@block.id}
      phx-hook="ContentEditable"
      phx-target={@myself}
      data-block
      data-selected={@selected}
      data-selection-start-id={@block.selection[:start_id]}
      data-selection-start-offset={@block.selection[:start_offset]}
      data-selection-end-id={@block.selection[:end_id]}
      data-selection-end-offset={@block.selection[:end_offset]}
    ><.content block={@block} /></h3>
    """
  end

  def render(%{block: %__MODULE__{type: "blockquote"}} = assigns) do
    ~H"""
    <blockquote
      class="philtre__block"
      contenteditable
      id={@block.id}
      phx-hook="ContentEditable"
      phx-target={@myself}
      data-block
      data-selected={@selected}
      data-selection-start-id={@block.selection[:start_id]}
      data-selection-start-offset={@block.selection[:start_offset]}
      data-selection-end-id={@block.selection[:end_id]}
      data-selection-end-offset={@block.selection[:end_offset]}
    ><.content block={@block} /></blockquote>
    """
  end

  def render(%{block: %__MODULE__{type: "li"}} = assigns) do
    ~H"""
    <ul>
      <li
        class="philtre__block"
        contenteditable
        id={@block.id}
        phx-hook="ContentEditable"
        phx-target={@myself}
        data-block
        data-selected={@selected}
        data-selection-start-id={@block.selection[:start_id]}
        data-selection-start-offset={@block.selection[:start_offset]}
        data-selection-end-id={@block.selection[:end_id]}
        data-selection-end-offset={@block.selection[:end_offset]}
      ><.content block={@block} /></li></ul>
    """
  end

  defp content(assigns) do
    ~H"<%= for cell <- @block.cells do %><.cell cell={cell} /><% end %>"
  end

  defp cell(%{cell: %{id: id, modifiers: modifiers, text: text}} = assigns) do
    classes = ["philtre-cell"] |> Enum.concat(modifiers) |> Enum.join(" ") |> String.trim()

    ~H"""
    <span data-cell-id={id} class={classes}><%= text %></span>
    """
  end

  def handle_event("update", %{"selection" => selection, "cells" => cells} = attrs, socket) do
    Logger.info("update: #{inspect(attrs)}")

    editor =
      Engine.update(socket.assigns.editor, socket.assigns.block, %{
        selection: selection,
        cells: cells
      })

    if editor !== socket.assigns.editor do
      send(self(), {:update, editor})
    end

    {:noreply, socket}
  end

  def handle_event("toggle." <> style, %{"selection" => selection} = attrs, socket) do
    Logger.info("toggle.#{style}: #{inspect(attrs)}")

    editor =
      Engine.toggle_style_on_selection(socket.assigns.editor, socket.assigns.block, %{
        selection: selection,
        style: style
      })

    if editor !== socket.assigns.editor do
      send(self(), {:update, editor})
    end

    {:noreply, socket}
  end

  def handle_event("split_line", %{"selection" => selection} = attrs, socket) do
    Logger.info("split_line: #{inspect(attrs)}")

    editor =
      Engine.split_line(socket.assigns.editor, socket.assigns.block, %{selection: selection})

    if editor !== socket.assigns.editor do
      send(self(), {:update, editor})
    end

    {:noreply, socket}
  end

  def handle_event("split_block", %{"selection" => selection} = attrs, socket) do
    Logger.info("split_block: #{inspect(attrs)}")

    editor =
      Engine.split_block(socket.assigns.editor, socket.assigns.block, %{selection: selection})

    if editor !== socket.assigns.editor do
      send(self(), {:update, editor})
    end

    {:noreply, socket}
  end

  def handle_event("backspace_from_start", %{} = attrs, socket) do
    Logger.info("backspace_from_start: #{inspect(attrs)}")
    editor = Engine.backspace_from_start(socket.assigns.editor, socket.assigns.block)

    if editor !== socket.assigns.editor do
      send(self(), {:update, editor})
    end

    {:noreply, socket}
  end

  def handle_event("paste_blocks", %{"selection" => selection} = attrs, socket) do
    Logger.info("paste_blocks: #{inspect(attrs)}")
    editor = Engine.paste(socket.assigns.editor, socket.assigns.block, %{selection: selection})

    if editor !== socket.assigns.editor do
      send(self(), {:update, editor})
    end

    {:noreply, socket}
  end
end
