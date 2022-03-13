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
end
