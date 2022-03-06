defmodule Editor.Block.H2 do
  @moduledoc """
  Holds logic specific to the h2 block
  """

  use Phoenix.LiveComponent
  use Phoenix.HTML

  alias Editor.Block
  alias Editor.Utils

  use Editor.ReactiveComponent, events: ["update", "backspace_from_start", "split"]

  defstruct [:content, :id]

  @type t :: %__MODULE__{}

  def render(%{block: %__MODULE__{}} = assigns) do
    ~H"""
    <h2
      contenteditable
      phx-hook="ContentEditable"
      phx-target={@myself}
      phx-debounce={500}
      id={@block.id}
    ><%= raw(@block.content) %></h2>
    """
  end

  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  def handle_event("split_line", %{}, socket), do: {:noreply, socket}

  def handle_event("split_block", %{"pre" => pre_content, "post" => post_content}, socket) do
    %__MODULE__{} = block = socket.assigns.block
    old_block = %{block | content: pre_content}
    new_block = %Block.P{id: Utils.new_id(), content: post_content}
    emit(socket, "replace", %{block: block, with: [old_block, new_block]})
    {:noreply, socket}
  end

  def handle_event("update", %{"value" => new_content}, socket) do
    old_block = socket.assigns.block
    new_block = %{old_block | content: new_content}
    emit(socket, "update", %{block: new_block})

    {:noreply, socket}
  end

  def handle_event("backspace_from_start", _, socket) do
    %__MODULE__{id: id, content: content} = socket.assigns.block
    new_block = %Block.H3{id: id, content: content}
    emit(socket, "update", %{block: new_block})
    {:noreply, socket}
  end

  @spec serialize(t) :: map
  def serialize(%__MODULE__{id: id, content: content}) do
    %{"id" => id, "type" => "h2", "content" => content}
  end

  @spec normalize(map) :: t
  def normalize(%{"id" => id, "type" => "h1", "content" => content}) do
    %__MODULE__{
      id: id,
      content: content
    }
  end

  def merge(%__MODULE__{} = self, %_{content: content}) do
    %{self | content: self.content <> content}
  end
end
