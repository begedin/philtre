defmodule PhiltreWeb.DocumentLive.Edit do
  @moduledoc """
  Implements the page for editing of an existing article.
  """
  use PhiltreWeb, :live_view

  alias Philtre.Documents

  def render(assigns) do
    ~H"""
    <button phx-click="save">Save</button>
    <.live_component module={Editor} id={@editor.id} editor={@editor} />
    """
  end

  @spec mount(map, PhiltreWeb.session(), LiveView.Socket.t()) :: {:ok, LiveView.Socket.t()}
  def mount(%{"filename" => filename}, _session, socket) do
    {:ok, %Editor{} = document} = Documents.get_document(filename)
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