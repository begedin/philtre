defmodule Editor do
  @moduledoc """
  Shared component used for both creation and editing of an article.
  """
  use PhiltreWeb, :live_component

  @spec update(
          %{optional(:slug) => String.t()},
          LiveView.Socket.t()
        ) :: {:ok, LiveView.Socket.t()}
  def update(%{page: page}, socket) do
    {:ok, assign(socket, :page, page)}
  end

  def update(%{}, socket) do
    {:ok, assign(socket, :page, Editor.Page.new())}
  end

  @spec handle_event(String.t(), map, LiveView.Socket.t()) :: {:noreply, LiveView.Socket.t()}

  def handle_event("add_block_after", %{"block_id" => id}, socket) do
    page = Editor.Page.add_block_after(socket.assigns.page, id)
    send(self(), {:updated_page, page})
    {:noreply, socket}
  end

  def handle_event("update_block", %{"block_id" => id, "value" => value}, socket) do
    page = Editor.Page.update_block(socket.assigns.page, id, value)
    send(self(), {:updated_page, page})
    {:noreply, socket}
  end

  def handle_event("downgrade_block", %{"block_id" => id}, socket) do
    page = Editor.Page.downgrade_block(socket.assigns.page, id)
    send(self(), {:updated_page, page})
    {:noreply, socket}
  end
end
