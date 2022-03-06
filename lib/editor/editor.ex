defmodule Editor do
  @moduledoc """
  Shared component used for both creation and editing of an article.
  """
  use Phoenix.LiveComponent
  use Phoenix.HTML

  use Editor.ReactiveComponent,
    events: ["update", "replace", "delete", "selection", "merge_previous"]

  alias Editor.Block
  alias Editor.Operations
  alias Editor.Serializer
  alias Editor.Utils

  alias Phoenix.LiveView

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
        %Block.H1{
          id: Utils.new_id(),
          content: "This is the title of your page"
        },
        %Block.P{
          id: Utils.new_id(),
          content: "This is your first paragraph."
        }
      ],
      selection: %{
        block_id: nil,
        id: Utils.new_id(),
        index: nil
      }
    }
  end

  @spec update(%{optional(:editor) => t()}, LiveView.Socket.t()) :: {:ok, LiveView.Socket.t()}

  def update(%{editor: _} = assigns, socket) do
    IO.inspect(assigns, label: "update")
    socket = assign(socket, assigns)
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div id={@editor.id}>
      <.selection editor={@editor} myself={@myself} />
      <div class="philtre__editor">
        <%= for %block_module{} = block <- @editor.blocks do %>
          <.live_component
            id={block.id}
            module={block_module}
            editor={@editor}
            block={block}
            parent={@editor}
            data-block-id={block.id},
            data-selected={block.id in @editor.selected_blocks}
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

  @spec handle_event(String.t(), map, LiveView.Socket.t()) :: {:noreply, LiveView.Socket.t()}

  def handle_event("select_blocks", %{"block_ids" => block_ids}, socket)
      when is_list(block_ids) do
    send(self(), {:update, %{socket.assigns.editor | selected_blocks: block_ids}})
    {:noreply, socket}
  end

  def handle_event("copy_blocks", %{"block_ids" => block_ids}, socket)
      when is_list(block_ids) do
    blocks = Enum.filter(socket.assigns.editor.blocks, &(&1.id in block_ids))
    send(self(), {:update, %{socket.assigns.editor | clipboard: blocks}})
    {:noreply, socket}
  end

  def handle_event("paste_blocks", %{"cell_id" => cell_id, "index" => index}, socket) do
    %Editor{} = editor = socket.assigns.editor

    if editor.clipboard != nil do
      new_editor = Operations.paste_blocks(editor, editor.clipboard, cell_id, index)
      send(self(), {:update, new_editor})
    end

    {:noreply, socket}
  end

  defdelegate serialize(editor), to: Serializer
  defdelegate normalize(editor), to: Serializer
  defdelegate text(editor), to: Serializer
  defdelegate html(editor), to: Serializer

  defp on(socket, "replace", %{block: block, with: blocks}) do
    editor = replace_block(socket.assigns.editor, block, blocks)
    send(self(), {:update, editor})
  end

  defp on(socket, "update", %{block: block}) do
    editor = replace_block(socket.assigns.editor, block, [block])
    send(self(), {:update, editor})

    {:ok, socket}
  end

  defp on(socket, "merge_previous", %{block: block}) do
    editor = socket.assigns.editor
    index = Enum.find_index(editor.blocks, &(&1 == block)) - 1

    if index >= 0 do
      %block_module{} = previous_block = Enum.at(editor.blocks, index)
      merged = block_module.merge(previous_block, block)
      blocks = editor.blocks |> List.delete_at(index + 1) |> List.replace_at(index, merged)
      editor = %{editor | blocks: blocks}

      send(self(), {:update, editor})
    end
  end

  defp on(socket, "delete", %_{} = block) do
    %__MODULE__{} = editor = socket.assigns.editor
    index = Enum.find_index(editor.blocks, &(&1.id === block.id))

    if index >= 1 do
      %block_type{} = previous_block = Enum.at(editor.blocks, index - 1)
      merged_block = block_type.merge(previous_block, block)

      active_cell_id = Enum.at(block.cells, 0).id

      blocks =
        editor.blocks
        |> List.delete_at(index)
        |> List.replace_at(index - 1, merged_block)

      editor = %{
        editor
        | blocks: blocks,
          selection: %{id: Utils.new_id(), cell_id: active_cell_id, index: 0}
      }

      send(self(), {:update, editor})
    end

    {:ok, socket}
  end

  defp replace_block(%__MODULE__{} = editor, %{id: _} = block, with_blocks) do
    index = Enum.find_index(editor.blocks, &(&1.id === block.id))
    blocks = editor.blocks |> List.replace_at(index, with_blocks) |> List.flatten()

    IO.inspect(%{index: index, block: block, with: with_blocks, new_blocks: blocks},
      label: "replace"
    )

    %{editor | blocks: blocks}
  end
end
