defmodule Philtre.UI.Page do
  @moduledoc """
  Shared component used for both creation and editing of an article.
  """
  use Phoenix.LiveComponent
  use Phoenix.HTML

  alias Philtre.LiveBlock
  alias Philtre.Editor
  alias Philtre.Editor.Engine
  alias Philtre.Editor.Utils

  alias Phoenix.LiveView.Socket

  require Logger

  @spec update(%{optional(:editor) => Editor.t()}, Socket.t()) :: {:ok, Socket.t()}

  def update(%{editor: new_editor} = updated_assigns, %Socket{} = socket) do
    undo_history = Map.get(socket.assigns, :undo_history, [])

    new_undo_history =
      case socket.assigns[:editor] do
        nil -> []
        current_editor -> Enum.take([current_editor | undo_history], 50)
      end

    redo_history = []

    focused_id =
      case socket.assigns[:focused_id] do
        nil -> Enum.at(new_editor.blocks, -1).id
        id -> id
      end

    new_assigns =
      Map.merge(
        %{
          undo_history: new_undo_history,
          redo_history: redo_history,
          focused_id: focused_id
        },
        updated_assigns
      )

    {:ok, assign(socket, new_assigns)}
  end

  def render(assigns) do
    ~H"""
    <div id={@editor.id}>
      <.selection editor={@editor} myself={@myself} />
      <.history editor={@editor} myself={@myself} />
      <div class="philtre-page">
        <%= for {block, index} <- Enum.with_index(@editor.blocks) do %>
          <.section {assigns} index={index} block={block}>
            <.sidebar block={block} myself={@myself} />
            <.block {assigns} block={block} tabindex={index} />
          </.section>
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

  defp section(assigns) do
    focused = assigns.focused_id === assigns.block.id

    ~H"""
    <div
      class="philtre-page__section"
      data-focused={focused}
      id={"section_#{@index}"}
      phx-hook="BlockNavigation"
      phx-target={@myself}
      tabindex={@index}
    >
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  def block(%{block: _} = assigns) do
    ~H"""
    <.live_component
      module={LiveBlock}
      {block_assigns(assigns)}
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

  defp block_assigns(%{block: %{id: id} = block, editor: editor}) do
    %{
      block: block,
      id: id,
      editor: editor,
      tabindex: Enum.find_index(editor.blocks, &(&1.id === id)),
      selected: id in editor.selected_blocks
    }
  end

  @spec handle_event(String.t(), map, Socket.t()) :: {:noreply, Socket.t()}
  def handle_event("select_blocks", %{"block_ids" => block_ids}, socket)
      when is_list(block_ids) do
    Logger.debug("select_blocks #{inspect(block_ids)}")
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
    %{id: id} = block = Enum.find(socket.assigns.editor.blocks, &(&1.id === block_id))
    %Editor{} = new_editor = Engine.add_block(socket.assigns.editor, block)
    new_index = Enum.find_index(new_editor.blocks, &(&1.id === id)) + 1
    %{id: new_id} = Enum.at(new_editor.blocks, new_index)
    {:noreply, assign(socket, editor: new_editor, focused_id: new_id)}
  end

  def handle_event("remove_block", %{"block_id" => block_id}, socket) do
    new_blocks = Enum.reject(socket.assigns.editor.blocks, &(&1.id === block_id))
    new_editor = %{socket.assigns.editor | blocks: new_blocks}

    {:noreply, assign(socket, :editor, new_editor)}
  end

  def handle_event("focus_previous", %{}, socket) do
    Logger.debug("focus_previous")

    with focused_id when is_binary(focused_id) <- socket.assigns[:focused_id],
         focused_index when is_integer(focused_index) <-
           Enum.find_index(socket.assigns.editor.blocks, &(&1.id === focused_id)),
         %{id: id} <- Enum.at(socket.assigns.editor.blocks, focused_index - 1) do
      {:noreply, assign(socket, :focused_id, id)}
    else
      _ -> {:noreply, socket}
    end
  end

  def handle_event("focus_next", %{}, socket) do
    Logger.debug("focus_next")

    with focused_id when is_binary(focused_id) <- socket.assigns[:focused_id],
         focused_index when is_integer(focused_index) <-
           Enum.find_index(socket.assigns.editor.blocks, &(&1.id === focused_id)),
         %{id: id} <- Enum.at(socket.assigns.editor.blocks, focused_index + 1) do
      {:noreply, assign(socket, :focused_id, id)}
    else
      _ -> {:noreply, socket}
    end
  end

  def handle_event("focus_current", %{"block_id" => id} = params, socket) do
    Logger.debug("focus_current, #{inspect(params)}")
    {:noreply, assign(socket, :focused_id, id)}
  end
end
