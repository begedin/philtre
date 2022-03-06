defmodule Editor.Block.Li do
  @moduledoc """
  Handles logic for a "ul" block
  """
  use Phoenix.LiveComponent
  use Phoenix.HTML
  use Editor.ReactiveComponent

  alias Editor.Block
  alias Editor.Utils

  defstruct [:content, :id]

  @type t :: %__MODULE__{}

  def render(%{block: %__MODULE__{}} = assigns) do
    ~H"""
    <ul>
      <li
        contenteditable
        id={@block.id}
        phx-hook="ContentEditable"
        phx-target={@myself}
      ><%= raw(@block.content) %></li>
    </ul>
    """
  end

  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
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
    old_block = %__MODULE__{block | content: pre_content}
    new_block = %__MODULE__{id: Utils.new_id(), content: post_content}
    emit(socket, "replace", %{block: block, with: [old_block, new_block]})
    {:noreply, socket}
  end

  def handle_event("backspace_from_start", _, socket) do
    %__MODULE__{content: content} = socket.assigns.block
    new_block = %Block.P{id: Utils.new_id(), content: content}
    emit(socket, "replace", %{block: socket.assigns.block, with: [new_block]})
    {:noreply, socket}
  end

  def merge(%__MODULE__{content: content} = this, %_{content: other_content}) do
    %{this | content: content <> other_content}
  end
end
