defmodule PhiltreWeb.ArticleLive.New do
  @moduledoc """
  Implements the page for creation of a new article.
  """
  use PhiltreWeb, :live_view

  alias Philtre.Articles

  @spec mount(map, PhiltreWeb.session(), LiveView.Socket.t()) :: {:ok, LiveView.Socket.t()}
  def mount(%{}, _session, socket) do
    {:ok, assign(socket, :editor, Editor.new())}
  end

  def render(assigns) do
    ~H"""
    <button phx-click="save">Save</button>
    <.live_component module={Editor} id={@editor.id} editor={@editor} />
    """
  end

  @errors_saving "There were some errors saving the article"

  def handle_event("save", %{}, socket) do
    %Editor{} = editor = socket.assigns.editor

    socket =
      case Articles.create_article(editor) do
        {:ok, _article} -> push_redirect(socket, to: "/articles")
        {:error, _changeset} -> put_flash(socket, :error, @errors_saving)
      end

    {:noreply, socket}
  end

  def handle_info({:emit, event, %module{id: id}, payload}, socket) do
    send_update(module, event: event, id: id, payload: payload)
    {:noreply, socket}
  end

  def handle_info({:update, %Editor{} = editor}, socket) do
    {:noreply, assign(socket, :editor, editor)}
  end
end
