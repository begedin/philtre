defmodule Playground.Live.New do
  use Phoenix.Component
  use Phoenix.HTML

  import Phoenix.LiveView.Helpers

  use Phoenix.LiveView, layout: {Playground.View, "live.html"}

  alias Philtre.Editor
  alias Philtre.UI.Page
  alias Phoenix.LiveView

  alias Playground.Documents

  @spec mount(map, struct, LiveView.Socket.t()) :: {:ok, LiveView.Socket.t()}
  def mount(%{}, _session, socket) do
    {:ok, assign(socket, :editor, Editor.new())}
  end

  def render(assigns) do
    ~H"""
    <form phx-submit="save">
      <input type="text" require name="filename">
      <button type="submit">Save</button>
    </form>
    <.live_component module={Page} id={@editor.id} editor={@editor} />
    """
  end

  def handle_event("save", %{"filename" => filename}, socket) do
    %Editor{} = editor = socket.assigns.editor

    :ok = Documents.save_document(editor, filename)
    {:noreply, push_redirect(socket, to: "/documents")}
  end

  def handle_info({:update, %Editor{} = editor}, socket) do
    {:noreply, assign(socket, :editor, editor)}
  end
end
