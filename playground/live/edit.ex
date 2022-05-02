defmodule Playground.Live.Edit do
  use Phoenix.Component
  use Phoenix.HTML

  import Phoenix.LiveView.Helpers

  use Phoenix.LiveView, layout: {Playground.View, "live.html"}

  alias Philtre.Editor
  alias Phoenix.LiveView
  alias Playground.Documents

  def render(assigns) do
    ~H"""
    <button phx-click="save">Save</button>
    <.live_component module={Editor} id={@editor.id} editor={@editor} />
    """
  end

  @spec mount(map, struct, LiveView.Socket.t()) :: {:ok, LiveView.Socket.t()}
  def mount(%{"filename" => filename}, _session, socket) do
    {:ok, %Philtre.Editor{} = document} = Documents.get_document(filename)
    {:ok, assign(socket, %{editor: document, filename: filename})}
  end

  def handle_event("save", %{}, socket) do
    :ok = Documents.save_document(socket.assigns.editor, socket.assigns.filename)
    {:noreply, push_redirect(socket, to: "/documents")}
  end

  def handle_info({:emit, event, %module{id: id}, payload}, socket) do
    send_update(module, event: event, id: id, payload: payload)
    {:noreply, socket}
  end

  def handle_info({:update, %Editor{} = editor}, socket) do
    {:noreply, assign(socket, :editor, editor)}
  end
end
