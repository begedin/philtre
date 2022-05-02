defmodule Philtre.Editor.Block do
  @moduledoc """
  Holds logic specific to the p block
  """

  use Phoenix.LiveComponent
  use Phoenix.HTML

  alias Philtre.Editor.Block
  alias Philtre.Editor.Engine
  alias Philtre.Editor.Utils

  require Logger

  # struct

  defstruct cells: [],
            id: Utils.new_id(),
            type: "p",
            selection: %Block.Selection{}

  @type id :: String.t()

  @type t :: %__MODULE__{
          id: id,
          cells: list(Block.Cell.t()),
          type: String.t(),
          selection: Block.Selection.t()
        }

  # component

  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  def render(%{block: %__MODULE__{type: "p"}} = assigns) do
    ~H"<p {attrs(@block, @selected, @myself)}><.content block={@block} /></p>"
  end

  def render(%{block: %__MODULE__{type: "pre"}} = assigns) do
    ~H"<pre {attrs(@block, @selected, @myself)}><.content block={@block} /></pre>"
  end

  def render(%{block: %__MODULE__{type: "h1"}} = assigns) do
    ~H"<h1 {attrs(@block, @selected, @myself)}><.content block={@block} /></h1>"
  end

  def render(%{block: %__MODULE__{type: "h2"}} = assigns) do
    ~H"<h2 {attrs(@block, @selected, @myself)}><.content block={@block} /></h2>"
  end

  def render(%{block: %__MODULE__{type: "h3"}} = assigns) do
    ~H"<h3 {attrs(@block, @selected, @myself)}><.content block={@block} /></h3>"
  end

  def render(%{block: %__MODULE__{type: "blockquote"}} = assigns) do
    ~H"<blockquote {attrs(@block, @selected, @myself)}><.content block={@block} /></blockquote>"
  end

  def render(%{block: %__MODULE__{type: "li"}} = assigns) do
    ~H"<ul><li {attrs(@block, @selected, @myself)}><.content block={@block} /></li></ul>"
  end

  defp content(assigns) do
    ~H"<%= for cell <- @block.cells do %><.cell cell={cell} /><% end %>"
  end

  defp cell(%{cell: %Block.Cell{id: id, modifiers: modifiers, text: text}} = assigns) do
    classes = ["philtre-cell"] |> Enum.concat(modifiers) |> Enum.join(" ") |> String.trim()

    ~H"<span data-cell-id={id} class={classes}><%= text %></span>"
  end

  defp attrs(%Block{} = block, selected, myself) when is_boolean(selected) do
    %{
      class: "philtre__block",
      contenteditable: true,
      data_block: true,
      data_selected: selected,
      data_selection_end_id: block.selection.end_id,
      data_selection_end_offset: block.selection.end_offset,
      data_selection_start_id: block.selection.start_id,
      data_selection_start_offset: block.selection.start_offset,
      id: block.id,
      phx_hook: "ContentEditable",
      phx_target: myself
    }
  end

  def handle_event("update", %{"selection" => selection, "cells" => cells} = attrs, socket) do
    Logger.info("update: #{inspect(attrs)}")

    editor =
      Engine.update(socket.assigns.editor, socket.assigns.block, %{
        selection: Block.Selection.normalize!(selection),
        cells: cells
      })

    if editor !== socket.assigns.editor do
      send(self(), {:update, editor})
    end

    {:noreply, socket}
  end

  def handle_event("toggle." <> style, %{"selection" => selection} = attrs, socket)
      when style in ["bold", "italic"] do
    Logger.info("toggle.#{style}: #{inspect(attrs)}")

    editor =
      Engine.toggle_style_on_selection(socket.assigns.editor, socket.assigns.block, %{
        selection: Block.Selection.normalize!(selection),
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
      Engine.split_line(socket.assigns.editor, socket.assigns.block, %{
        selection: Block.Selection.normalize!(selection)
      })

    if editor !== socket.assigns.editor do
      send(self(), {:update, editor})
    end

    {:noreply, socket}
  end

  def handle_event("split_block", %{"selection" => selection} = attrs, socket) do
    Logger.info("split_block: #{inspect(attrs)}")

    editor =
      Engine.split_block(socket.assigns.editor, socket.assigns.block, %{
        selection: Block.Selection.normalize!(selection)
      })

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

    editor =
      Engine.paste(socket.assigns.editor, socket.assigns.block, %{
        selection: Block.Selection.normalize!(selection)
      })

    if editor !== socket.assigns.editor do
      send(self(), {:update, editor})
    end

    {:noreply, socket}
  end
end
