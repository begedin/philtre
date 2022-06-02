defmodule Philtre.UI.Page do
  @moduledoc """
  Shared component used for both creation and editing of an article.
  """
  use Phoenix.LiveComponent
  use Phoenix.HTML

  alias Philtre.Code
  alias Philtre.Editor
  alias Philtre.Editor.Block
  alias Philtre.Editor.Engine
  alias Philtre.Editor.Utils
  alias Philtre.Table

  alias Phoenix.LiveView.Socket

  require Logger

  @spec update(%{optional(:editor) => Editor.t()}, Socket.t()) :: {:ok, Socket.t()}

  def update(%{editor: new_editor}, %Socket{} = socket) do
    case Map.get(socket.assigns, :editor) do
      nil ->
        {:ok, assign(socket, %{editor: new_editor})}

      %Editor{} = current_editor ->
        undo_history = Map.get(socket.assigns, :undo_history, [])

        socket =
          assign(socket, %{
            editor: new_editor,
            undo_history: Enum.take([current_editor | undo_history], 50),
            redo_history: []
          })

        {:ok, socket}
    end
  end

  def render(assigns) do
    ~H"""
    <div id={@editor.id}>
      <.selection editor={@editor} myself={@myself} />
      <.history editor={@editor} myself={@myself} />
      <div class="philtre-page">
        <%= for block <- @editor.blocks do %>
          <div class="philtre-page__section">
            <.sidebar block={block} myself={@myself} />
            <.block {assigns} block={block} />
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  defp selection(%{editor: _} = assigns) do
    ~H"""
    <div
      class="philtre-selection"
      id={"editor__selection__#{@editor.id}"}
      phx-hook="Selection"
      phx-target={@myself}
    />
    """
  end

  defp history(%{editor: _} = assigns) do
    ~H"""
    <div
      class="philtre-history"
      id={"editor__history__#{@editor.id}"}
      phx-hook="History"
      phx-target={@myself}
    />
    """
  end

  def block(%{block: %Block{}} = assigns) do
    ~H"""
    <.live_component
      id={@block.id}
      module={Block}
      editor={@editor}
      block={@block}
      selected={@block.id in @editor.selected_blocks}
    />
    """
  end

  def block(%{block: %Table{}} = assigns) do
    ~H"""
    <.live_component
      module={Table}
      id={@block.id}
      editor={@editor}
      block={@block}
      selected={@block.id in @editor.selected_blocks}
    />
    """
  end

  def block(%{block: %Code{}} = assigns) do
    ~H"""
    <.live_component
      module={Code}
      id={@block.id}
      editor={@editor}
      block={@block}
      selected={@block.id in @editor.selected_blocks}
    />
    """
  end

  def sidebar(%{block: _} = assigns) do
    ~H"""
    <div class="philtre-sidebar">
      <button
        phx-click="add_block"
        phx-value-block_id={@block.id}
        phx-target={@myself}
      >
        +
      </button>
      <button
        phx-click="remove_block"
        phx-value-block_id={@block.id}
        phx-target={@myself}
      >
        -
      </button>
    </div>
    """
  end

  @spec handle_event(String.t(), map, Socket.t()) :: {:noreply, Socket.t()}
  def handle_event("select_blocks", %{"block_ids" => block_ids}, socket)
      when is_list(block_ids) do
    send(self(), {:update, %{socket.assigns.editor | selected_blocks: block_ids}})
    {:noreply, socket}
  end

  def handle_event("copy_blocks", %{"block_ids" => block_ids}, socket)
      when is_list(block_ids) do
    blocks =
      socket.assigns.editor.blocks
      |> Enum.filter(&(&1.id in block_ids))
      |> Enum.map(&%{&1 | id: Utils.new_id()})

    send(self(), {:update, %{socket.assigns.editor | clipboard: blocks}})
    {:noreply, socket}
  end

  def handle_event("undo", %{}, socket) do
    Logger.info("undo")

    case Map.get(socket.assigns, :undo_history) do
      [] ->
        {:noreply, socket}

      [last_version | rest] ->
        current_editor = socket.assigns.editor
        redo_history = Map.get(socket.assigns, :redo_history, [])

        socket =
          assign(socket, %{
            editor: last_version,
            undo_history: rest,
            redo_history: [current_editor | redo_history]
          })

        {:noreply, socket}
    end
  end

  def handle_event("redo", %{}, socket) do
    Logger.info("redo")

    case Map.get(socket.assigns, :redo_history) do
      [] ->
        {:noreply, socket}

      [last_version | rest] ->
        current_editor = socket.assigns.editor
        undo_history = Map.get(socket.assigns, :undo_history, [])

        socket =
          assign(socket, %{
            editor: last_version,
            redo_history: rest,
            undo_history: [current_editor | undo_history]
          })

        {:noreply, socket}
    end
  end

  def handle_event("add_block", %{"block_id" => block_id}, socket) do
    block = Enum.find(socket.assigns.editor.blocks, &(&1.id === block_id))
    new_editor = Engine.add_block(socket.assigns.editor, block)
    {:noreply, assign(socket, :editor, new_editor)}
  end

  def handle_event("remove_block", %{"block_id" => block_id}, socket) do
    new_blocks = Enum.reject(socket.assigns.editor.blocks, &(&1.id === block_id))
    new_editor = %{socket.assigns.editor | blocks: new_blocks}

    {:noreply, assign(socket, :editor, new_editor)}
  end
end
