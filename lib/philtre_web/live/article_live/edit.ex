defmodule PhiltreWeb.ArticleLive.Edit do
  @moduledoc """
  Implements the page for editing of an existing article.
  """
  use PhiltreWeb, :live_view

  alias Philtre.Articles

  def render(assigns) do
    ~H"""
    <button phx-click="save">Save</button>
    <.live_component module={Editor} id={@editor.id} editor={@editor} />
    """
  end

  @spec mount(map, PhiltreWeb.session(), LiveView.Socket.t()) :: {:ok, LiveView.Socket.t()}
  def mount(%{"slug" => slug}, _session, socket) do
    {:ok, %Articles.Article{} = article} = Articles.get_article(slug)
    editor = Editor.normalize(article.content)
    {:ok, assign(socket, %{article: article, editor: editor})}
  end

  @errors_saving "There were some errors saving the article"

  def handle_event("save", %{}, socket) do
    %Articles.Article{} = article = socket.assigns.article
    %Editor{} = editor = socket.assigns.editor

    case Articles.update_article(article, editor) do
      {:ok, _article} -> {:noreply, push_redirect(socket, to: "/articles")}
      {:error, _changeset} -> {:noreply, put_flash(socket, :error, @errors_saving)}
    end
  end

  def handle_info({:emit, event, %module{id: id}, payload}, socket) do
    send_update(module, event: event, id: id, payload: payload)
    {:noreply, socket}
  end

  def handle_info({:update, %Editor{} = editor}, socket) do
    {:noreply, assign(socket, :editor, editor)}
  end
end
