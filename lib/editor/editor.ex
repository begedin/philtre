defmodule Editor do
  @moduledoc """
  Shared component used for both creation and editing of an article.
  """
  use Phoenix.LiveComponent
  use Phoenix.HTML

  alias Editor.Block
  alias Editor.BlockEngine
  alias Editor.Serializer
  alias Editor.Utils

  alias Phoenix.LiveView
  alias Phoenix.LiveView.Socket

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
          active: false,
          pre_caret: "This is the title of your page",
          post_caret: ""
        },
        %Block.P{
          id: Utils.new_id(),
          active: true,
          pre_caret: "This is your first paragraph.",
          post_caret: ""
        }
      ]
    }
  end

  @spec update(%{optional(:editor) => t()}, Socket.t()) :: {:ok, Socket.t()}

  def update(%{editor: _} = assigns, %Socket{} = socket) do
    {:ok, assign(socket, assigns)}
  end

  def update(%{event: event, payload: payload}, %Socket{} = socket) do
    handle_child_event(socket, event, payload)
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

  @spec handle_event(String.t(), map, LiveView.Socket.t()) :: {:noreply, LiveView.Socket.t()}

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

  defdelegate serialize(editor), to: Serializer
  defdelegate normalize(editor), to: Serializer
  defdelegate text(editor), to: Serializer
  defdelegate html(editor), to: Serializer

  def send_event(%Socket{} = socket, event, payload) do
    %Editor{} = editor = socket.assigns.editor

    send_update(Editor, event: event, id: editor.id, payload: payload)
  end

  defp handle_child_event(%Socket{} = socket, "replace", %{block: block, with: blocks}) do
    %Editor{} = editor = socket.assigns.editor
    index = Enum.find_index(editor.blocks, &(&1.id === block.id))
    blocks = editor.blocks |> List.replace_at(index, blocks) |> List.flatten()

    editor = %{editor | blocks: blocks}
    send(self(), {:update, editor})
  end

  defp handle_child_event(%Socket{} = socket, "merge_previous", %{block: block}) do
    editor = socket.assigns.editor
    index = Enum.find_index(editor.blocks, &(&1 == block)) - 1

    if index >= 0 do
      %_{} = previous_block = Enum.at(editor.blocks, index)
      merged = BlockEngine.merge(previous_block, block)
      blocks = editor.blocks |> List.delete_at(index + 1) |> List.replace_at(index, merged)
      editor = %{editor | blocks: blocks}

      send(self(), {:update, editor})
    else
      socket
    end
  end
end
