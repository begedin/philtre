defmodule PlaygroundWeb.DocumentLive.Index do
  @moduledoc """
  Implements the page for listing articles in the admin interface.

  From here, users can manage each individual article.
  """
  use PlaygroundWeb, :live_view

  alias Playground.Documents

  @spec mount(map, PlaygroundWeb.session(), LiveView.Socket.t()) :: {:ok, LiveView.Socket.t()}
  def mount(%{}, _session, socket) do
    socket = assign(socket, :documents, Documents.list_documents())
    {:ok, socket}
  end

  def handle_params(%{}, _path, socket) do
    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <div>
      <%= for filename <- @documents do %>
      <div>
        <%= live_patch(filename, to: "/documents/#{filename}/edit") %>
      </div>
      <% end %>
    </div>

    """
  end
end
