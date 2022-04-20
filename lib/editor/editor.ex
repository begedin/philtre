defmodule Editor do
  @moduledoc """
  Shared component used for both creation and editing of an article.
  """
  use Phoenix.LiveComponent
  use Phoenix.HTML

  alias Editor.Block
  alias Editor.Serializer
  alias Editor.Utils

  alias Phoenix.LiveView.Socket

  require Logger

  defstruct blocks: [],
            clipboard: nil,
            id: nil,
            selected_blocks: [],
            selection: nil

  @type t :: %__MODULE__{}

  def new do
    %__MODULE__{
      id: Utils.new_id(),
      blocks: [
        %Block{
          id: Utils.new_id(),
          cells: [
            %Block.Cell{id: Utils.new_id(), text: "This is the title of your page", modifiers: []}
          ],
          selection: %Block.Selection{},
          type: "h1"
        },
        %Block{
          id: Utils.new_id(),
          cells: [
            %Block.Cell{id: Utils.new_id(), text: "This is your first paragraph.", modifiers: []}
          ],
          selection: %Block.Selection{},
          type: "p"
        }
      ]
    }
  end

  @spec update(%{optional(:editor) => t()}, Socket.t()) :: {:ok, Socket.t()}

  def update(%{editor: new_editor}, %Socket{} = socket) do
    case Map.get(socket.assigns, :editor) do
      nil ->
        {:ok, assign(socket, %{editor: new_editor})}

      %__MODULE__{} = current_editor ->
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
      <div class="philtre__editor">
        <%= for %Block{} = block <- @editor.blocks do %>
          <.live_component
            id={block.id}
            module={Block}
            editor={@editor}
            block={block}
            selected={block.id in @editor.selected_blocks}
          />
        <% end %>
      </div>
    </div>
    """
  end

  defp selection(%{editor: _} = assigns) do
    ~H"""
    <div
      class="philtre__selection"
      id={"editor__selection__#{@editor.id}"}
      phx-hook="Selection"
      phx-target={@myself}
    />
    """
  end

  defp history(%{editor: _} = assigns) do
    ~H"""
    <div
      class="philtre__history"
      id={"editor__history__#{@editor.id}"}
      phx-hook="History"
      phx-target={@myself}
    />
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

  defdelegate serialize(editor), to: Serializer
  defdelegate normalize(editor), to: Serializer
  defdelegate text(editor), to: Serializer
  defdelegate html(editor), to: Serializer
end
