defmodule Playground.Live.Index do
  use Phoenix.Component
  use Phoenix.HTML

  import Phoenix.LiveView.Helpers

  use Phoenix.LiveView, layout: {Playground.View, :live}

  alias Phoenix.LiveView
  alias Playground.Documents

  @spec mount(map, struct, LiveView.Socket.t()) :: {:ok, LiveView.Socket.t()}
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
