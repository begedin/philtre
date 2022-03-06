defmodule Editor.Block.Blockquote do
  @moduledoc """
  Holds logic specific to the BLOCKQUOTE block
  """

  use Phoenix.LiveComponent
  use Phoenix.HTML
  use Editor.ReactiveComponent, events: ["update", "backspace_from_start", "split"]

  alias Editor.Block
  alias Editor.Utils

  defstruct [:content, :id]

  @type t :: %__MODULE__{}

  def render(%{block: %__MODULE__{}} = assigns) do
    ~H"""
    <blockquote
      contenteditable
      phx-hook="ContentEditable"
      phx-target={@myself}
      phx-debounce={500}
      id={@block.id}
    ><%= raw(@block.content) %></blockquote>
    """
  end

  def handle_event("update", %{"value" => new_content}, socket) do
    old_block = socket.assigns.block
    new_block = %{old_block | content: new_content}
    emit(socket, "update", %{block: new_block})

    {:noreply, socket}
  end

  def handle_event("split_line", %{}, socket), do: {:noreply, socket}

  def handle_event("split_block", %{"pre" => pre_content, "post" => post_content}, socket) do
    %__MODULE__{} = block = socket.assigns.block
    old_block = %{block | content: pre_content}
    new_block = %__MODULE__{id: Utils.new_id(), content: post_content}
    emit(socket, "replace", %{block: block, with: [old_block, new_block]})
    {:noreply, socket}
  end

  def handle_event("backspace_from_start", _, socket) do
    %__MODULE__{id: id, content: content} = socket.assigns.block
    new_block = %Block.P{id: id, content: content}
    emit(socket, "update", %{block: new_block})
    {:noreply, socket}
  end

  @spec serialize(t) :: map
  def serialize(%__MODULE__{id: id, content: content}) do
    %{"id" => id, "type" => "blockquote", "content" => content}
  end

  @spec normalize(map) :: t
  def normalize(%{"id" => id, "type" => "blockquote", "content" => content}) do
    %__MODULE__{
      id: id,
      content: content
    }
  end
end
